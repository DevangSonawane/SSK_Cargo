const statusConfig = {
  'Requested':       'bg-blue-50 text-blue-700 border-blue-200',
  'Accepted':        'bg-indigo-50 text-indigo-700 border-indigo-200',
  'Assigned':        'bg-violet-50 text-violet-700 border-violet-200',
  'En Route':        'bg-cyan-50 text-cyan-700 border-cyan-200',
  'En Route Pickup': 'bg-cyan-50 text-cyan-700 border-cyan-200',
  'Picked Up':       'bg-sky-50 text-sky-700 border-sky-200',
  'In Transit':      'bg-amber-50 text-amber-700 border-amber-200',
  'Delivered':       'bg-emerald-50 text-emerald-700 border-emerald-200',
  'Completed':       'bg-green-50 text-green-700 border-green-200',
  'Cancelled':       'bg-red-50 text-red-700 border-red-200',
  'Active':          'bg-green-50 text-green-700 border-green-200',
  'Inactive':        'bg-neutral-100 text-neutral-500 border-neutral-200',
  'Blocked':         'bg-red-50 text-red-700 border-red-200',
  'Client':          'bg-blue-50 text-blue-700 border-blue-200',
  'Broker':          'bg-violet-50 text-violet-700 border-violet-200',
  'Driver':          'bg-amber-50 text-amber-700 border-amber-200',
  'Admin':           'bg-secondary/10 text-secondary border-secondary/20',
  'Available':       'bg-green-50 text-green-700 border-green-200',
  'Offline':         'bg-neutral-100 text-neutral-500 border-neutral-200',
  'On Trip':         'bg-amber-50 text-amber-700 border-amber-200',
  'Under Maintenance':'bg-orange-50 text-orange-700 border-orange-200',
  'Verified':        'bg-green-50 text-green-700 border-green-200',
  'Pending':         'bg-amber-50 text-amber-700 border-amber-200',
  'Rejected':        'bg-red-50 text-red-700 border-red-200',
  'Open':            'bg-red-50 text-red-700 border-red-200',
  'Under Review':    'bg-blue-50 text-blue-700 border-blue-200',
  'Resolved':        'bg-green-50 text-green-700 border-green-200',
  'Paid':            'bg-green-50 text-green-700 border-green-200',
  'Refund':          'bg-orange-50 text-orange-700 border-orange-200',
  'Refunded':        'bg-orange-50 text-orange-700 border-orange-200',
};

export default function Badge({ status, children }) {
  const cls = statusConfig[status] || 'bg-neutral-100 text-neutral-600 border-neutral-200';
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold border ${cls}`}>
      <span className="w-1.5 h-1.5 rounded-full bg-current opacity-80 flex-shrink-0" />
      {children || status}
    </span>
  );
}
