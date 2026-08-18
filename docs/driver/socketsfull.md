1.⁠ ⁠Architecture: one socket connection, alive for the whole app session
Don't open a socket per-screen. Connect once (e.g. right after login, in a top-level service/singleton), keep it open as long as the driver is logged in, and let any screen subscribe to it.


// lib/services/socket_service.dart
class SocketService {
  static final SocketService instance = SocketService._();
  SocketService._();

  io.Socket? _socket;
  final _driverRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get driverRequestUpdates => _driverRequestController.stream;
  Stream<Map<String, dynamic>> get paymentUpdates => _paymentController.stream;

  void connect(String accessToken) {
    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': accessToken})
      .build());

    _socket!.on('driver-request-updated', (data) => _driverRequestController.add(Map<String, dynamic>.from(data)));
    _socket!.on('booking-payment-updated', (data) => _paymentController.add(Map<String, dynamic>.from(data)));

    _socket!.connect();
  }

  void disconnect() => _socket?.disconnect();
}
Package: socket_io_client. Auth exactly like the web apps — auth: { token: accessToken }. The moment this connects, the server auto-joins the driver to their own room (user:{driverId}) — nothing else to subscribe to.

2.⁠ ⁠Requests page — new offers appear automatically
The Requests page just listens to the broadcast stream and merges updates into its list. It does not open its own socket connection — it reuses the app-wide one.


class RequestsPage extends StatefulWidget {
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<DriverRequest> requests = [];
  StreamSubscription? _sub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitial(); // GET /api/driver-requests  -> populate list once on screen open

    // Live updates: new offer, or any status change to one already in the list.
    _sub = SocketService.instance.driverRequestUpdates.listen((payload) {
      final incoming = DriverRequest.fromJson(payload);
      setState(() {
        final i = requests.indexWhere((r) => r.id == incoming.id);
        if (i == -1) {
          requests.insert(0, incoming); // brand new offer
        } else {
          requests[i] = incoming; // existing offer changed (countered/accepted/declined)
        }
      });

      if (incoming.status == 'accepted' && incoming.driverId == myUserId) {
        _goToActiveTrip(); // see §3
      }
    });

    // Fallback only — socket can drop. Back this off or drop it once you've confirmed
    // the socket is healthy; don't rely on it as the primary mechanism.
    pollTimer = Timer.periodic(const Duration(seconds: 12), () => _loadInitial());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
Backend contract this relies on (already live, nothing to add server-side):

POST /api/bookings/{id}/request-truck (client picks this driver directly) or POST /api/jobs/{id}/assign-driver (broker assigns this driver) — both create a driver_requests row and immediately emit driver-request-updated to user:{driverId}.
Payload is the full request object (id, bookingId, bookingNumber, amount, status, driverTimedOut, pickup, drop, ...) — swap it straight into your list, no re-fetch needed.
GET /api/driver-requests is the fallback/initial-load call.
3.⁠ ⁠Accept → Active Trip
Two things matter here: the accept call itself already tells you the trip exists — you don't need to wait for a second socket event to know it worked.


Future<void> onAcceptTapped(DriverRequest request) async {
  try {
    final res = await api.patch('/api/driver-requests/${request.id}/accept');
    // res.data.request.status == "accepted" — the booking is finalized RIGHT NOW,
    // a trip already exists server-side. No further confirmation step needed.
    await _goToActiveTrip();
  } on ApiException catch (e) {
    if (e.statusCode == 400) {
      // Already actioned / not your turn anymore (e.g. broker took over after timeout,
      // or the client cancelled). Re-fetch the request and update the UI from fresh state.
      _loadInitial();
    }
  }
}

Future<void> _goToActiveTrip() async {
  final res = await api.get('/api/trips/upcoming'); // status still "confirmed", not started
  final trip = Trip.fromJson(res.data['trip']);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => ActiveTripPage(trip: trip)),
    (route) => route.isFirst, // clear Requests off the back stack — no going "back" into a stale offer
  );
}
Why pushAndRemoveUntil and not push: once accepted, the Requests-list entry for this booking is dead — there's nothing useful to go "back" to. Same reasoning applies if the other trigger fires instead: the driver is sitting on the Requests page, doesn't tap anything themselves, and the client independently calls client-accept (their side) — the driver still gets driver-request-updated with status: "accepted" pushed to them (see the if (incoming.status == 'accepted' ...) branch in §2), and should jump to Active Trip exactly the same way, without having tapped Accept at all. Both paths — you accepting, or the client accepting first — must lead to the same _goToActiveTrip() call.

GET /api/trips/upcoming vs GET /api/trips/active: use upcoming right after acceptance (trip status is still confirmed, driver hasn't tapped "Start Trip to Pickup" yet) and active for reloading the trip screen on subsequent app opens (works once status has moved past confirmed).

4.⁠ ⁠One more edge case worth building for
If the driver taps Accept at the same moment the client (or the broker, if the driver had timed out) resolves it a different way, the accept call returns 409/400 instead of succeeding — show "This offer is no longer available" and pop back to the Requests list refreshed, don't retry silently.