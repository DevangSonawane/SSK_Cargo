part of '../client_flow_widgets.dart';

/// Pincodes we currently serve for loading, grouped by city (India Post
/// division). Source: Delhi and Haryana serviceable pincode lists.
const Map<String, List<String>> _serviceablePincodesByCity = {
  'Delhi': [
    '110001',
    '110002',
    '110003',
    '110004',
    '110005',
    '110006',
    '110007',
    '110008',
    '110009',
    '110010',
    '110011',
    '110012',
    '110013',
    '110014',
    '110015',
    '110016',
    '110017',
    '110018',
    '110019',
    '110020',
    '110021',
    '110022',
    '110023',
    '110024',
    '110025',
    '110026',
    '110027',
    '110028',
    '110029',
    '110030',
    '110031',
    '110032',
    '110033',
    '110034',
    '110035',
    '110036',
    '110037',
    '110038',
    '110039',
    '110040',
    '110041',
    '110042',
    '110043',
    '110044',
    '110045',
    '110046',
    '110047',
    '110048',
    '110049',
    '110051',
    '110052',
    '110053',
    '110054',
    '110055',
    '110056',
    '110057',
    '110058',
    '110059',
    '110060',
    '110061',
    '110062',
    '110063',
    '110064',
    '110065',
    '110066',
    '110067',
    '110068',
    '110069',
    '110070',
    '110071',
    '110072',
    '110073',
    '110074',
    '110075',
    '110076',
    '110077',
    '110078',
    '110080',
    '110081',
    '110082',
    '110083',
    '110084',
    '110085',
    '110086',
    '110087',
    '110088',
    '110089',
    '110090',
    '110091',
    '110092',
    '110093',
    '110094',
    '110095',
    '110096',
    '110097',
    '110099',
    '110110',
  ],
  'Ambala': [
    '133001',
    '133004',
    '133005',
    '133006',
    '133008',
    '133010',
    '133101',
    '133102',
    '133103',
    '133104',
    '133201',
    '133202',
    '133203',
    '133204',
    '133205',
    '133206',
    '133207',
    '133301',
    '133302',
    '134003',
    '134005',
    '134007',
    '134008',
    '134101',
    '134102',
    '134103',
    '134104',
    '134105',
    '134107',
    '134108',
    '134109',
    '134112',
    '134113',
    '134114',
    '134116',
    '134117',
    '134118',
    '134201',
    '134202',
    '134203',
    '134204',
    '134205',
    '135001',
    '135002',
    '135003',
    '135004',
    '135021',
    '135101',
    '135102',
    '135103',
    '135106',
    '135133',
  ],
  'Bhiwani': [
    '127021',
    '127022',
    '127025',
    '127026',
    '127027',
    '127028',
    '127029',
    '127030',
    '127031',
    '127032',
    '127035',
    '127040',
    '127041',
    '127042',
    '127043',
    '127045',
    '127046',
    '127111',
    '127114',
    '127201',
    '127306',
    '127307',
    '127308',
    '127309',
    '127310',
    '127311',
    '127312',
  ],
  'Faridabad': [
    '121001',
    '121002',
    '121003',
    '121004',
    '121005',
    '121006',
    '121007',
    '121008',
    '121009',
    '121010',
    '121012',
    '121013',
    '121014',
    '121015',
    '121101',
    '121102',
    '121103',
    '121105',
    '121106',
    '121107',
  ],
  'Gurgaon': [
    '122001',
    '122002',
    '122003',
    '122004',
    '122005',
    '122006',
    '122007',
    '122008',
    '122009',
    '122010',
    '122011',
    '122012',
    '122015',
    '122016',
    '122017',
    '122018',
    '122051',
    '122052',
    '122098',
    '122101',
    '122102',
    '122103',
    '122104',
    '122105',
    '122107',
    '122108',
    '122413',
    '122414',
    '122502',
    '122503',
    '122504',
    '122505',
    '122506',
    '122508',
    '123001',
    '123021',
    '123023',
    '123024',
    '123027',
    '123028',
    '123029',
    '123031',
    '123034',
    '123035',
    '123101',
    '123102',
    '123103',
    '123106',
    '123110',
    '123301',
    '123302',
    '123303',
    '123401',
    '123411',
    '123412',
    '123501',
  ],
  'Hissar': [
    '125001',
    '125004',
    '125005',
    '125006',
    '125007',
    '125011',
    '125033',
    '125037',
    '125038',
    '125039',
    '125042',
    '125044',
    '125047',
    '125048',
    '125049',
    '125050',
    '125051',
    '125052',
    '125053',
    '125054',
    '125055',
    '125056',
    '125058',
    '125060',
    '125075',
    '125076',
    '125077',
    '125078',
    '125101',
    '125102',
    '125103',
    '125104',
    '125106',
    '125110',
    '125111',
    '125112',
    '125113',
    '125120',
    '125121',
    '125133',
    '125201',
  ],
  'Karnal': [
    '126101',
    '126102',
    '126110',
    '126111',
    '126112',
    '126113',
    '126114',
    '126115',
    '126116',
    '126125',
    '126152',
    '132001',
    '132022',
    '132023',
    '132024',
    '132036',
    '132037',
    '132039',
    '132040',
    '132041',
    '132046',
    '132054',
    '132101',
    '132102',
    '132103',
    '132104',
    '132105',
    '132106',
    '132107',
    '132108',
    '132113',
    '132114',
    '132115',
    '132116',
    '132117',
    '132122',
    '132140',
    '132145',
    '132157',
  ],
  'Kurukshetra': [
    '136020',
    '136021',
    '136026',
    '136027',
    '136030',
    '136033',
    '136034',
    '136035',
    '136038',
    '136042',
    '136043',
    '136044',
    '136117',
    '136118',
    '136119',
    '136128',
    '136129',
    '136130',
    '136131',
    '136132',
    '136134',
    '136135',
    '136136',
    '136156',
  ],
  'Rohtak': [
    '124001',
    '124010',
    '124021',
    '124022',
    '124102',
    '124103',
    '124104',
    '124105',
    '124106',
    '124107',
    '124108',
    '124109',
    '124111',
    '124112',
    '124113',
    '124141',
    '124142',
    '124146',
    '124201',
    '124202',
    '124303',
    '124401',
    '124404',
    '124406',
    '124411',
    '124412',
    '124501',
    '124504',
    '124505',
    '124506',
    '124507',
    '124508',
    '124513',
    '124514',
  ],
  'Sonepat': [
    '131001',
    '131021',
    '131022',
    '131023',
    '131024',
    '131027',
    '131028',
    '131029',
    '131030',
    '131039',
    '131101',
    '131102',
    '131103',
    '131301',
    '131302',
    '131304',
    '131305',
    '131306',
    '131402',
    '131403',
    '131408',
    '131409',
  ],
};

Future<void> _showServiceableAreasSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ServiceableAreasSheet(),
  );
}

class _ServiceableAreasSheet extends StatefulWidget {
  const _ServiceableAreasSheet();

  @override
  State<_ServiceableAreasSheet> createState() => _ServiceableAreasSheetState();
}

class _ServiceableAreasSheetState extends State<_ServiceableAreasSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// A city-name match shows all of that city's pincodes; otherwise only the
  /// pincodes containing the typed digits are kept.
  List<MapEntry<String, List<String>>> get _filteredCities {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _serviceablePincodesByCity.entries.toList();
    }
    return [
      for (final entry in _serviceablePincodesByCity.entries)
        if (entry.key.toLowerCase().contains(query))
          entry
        else if (entry.value.any((pincode) => pincode.contains(query)))
          MapEntry(
            entry.key,
            entry.value.where((pincode) => pincode.contains(query)).toList(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final cities = _filteredCities;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Icon(
                    AppIcons.info_outline_rounded,
                    size: 20,
                    color: context.colors.infoEmphasis,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.serviceableAreasTitle,
                      style: textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.serviceableAreasSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.serviceableAreasSearchHint,
                  prefixIcon: const Icon(AppIcons.search_rounded, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(AppIcons.close_rounded, size: 18),
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: context.colors.fillSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: context.colors.divider),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  _sheetBottomInset(context),
                ),
                children: [
                  if (cities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          l10n.serviceableAreasNoResults,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  for (final entry in cities)
                    _ServiceableCitySection(
                      city: entry.key,
                      pincodes: entry.value,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceableCitySection extends StatelessWidget {
  const _ServiceableCitySection({required this.city, required this.pincodes});

  final String city;
  final List<String> pincodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.location_on_rounded,
                size: 16,
                color: context.colors.brandEmphasis,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  city,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l10n.serviceableAreasPincodeCount(pincodes.length),
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pincode in pincodes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pincode,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _UnserviceableAction { changeLocation }

/// Geofence rejection from validate-location or booking create. Matches the
/// message too, in case a server build answers without `errors.code`.
bool _isUnserviceableError(Object error) =>
    error is ApiException &&
    (error.code == 'PINCODE_NOT_SERVICEABLE' ||
        RegExp(
          r'not (currently )?service|not serviceable',
          caseSensitive: false,
        ).hasMatch(error.message));

Future<_UnserviceableAction?> _showUnserviceableLocationSheet(
  BuildContext context, {
  required _LocationFieldKind kind,
  required String pincode,
}) {
  return showModalBottomSheet<_UnserviceableAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _UnserviceableLocationSheet(kind: kind, pincode: pincode),
  );
}

class _UnserviceableLocationSheet extends StatelessWidget {
  const _UnserviceableLocationSheet({
    required this.kind,
    required this.pincode,
  });

  final _LocationFieldKind kind;
  final String pincode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isPickup = kind == _LocationFieldKind.pickup;
    return Padding(
      padding: EdgeInsets.only(bottom: _sheetBottomInset(context)),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.dangerEmphasis.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.location_off_outlined,
                size: 28,
                color: context.colors.dangerEmphasis,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.unserviceableTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPickup
                  ? l10n.unserviceablePickupBody
                  : l10n.unserviceableDropBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (pincode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.fillSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.unserviceablePincode(pincode),
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_UnserviceableAction.changeLocation),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(
                  isPickup
                      ? l10n.unserviceableChangePickup
                      : l10n.unserviceableChangeDrop,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showServiceableAreasSheet(context),
                icon: const Icon(AppIcons.info_outline_rounded, size: 17),
                label: Text(l10n.unserviceableViewAreas),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.infoEmphasis,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
