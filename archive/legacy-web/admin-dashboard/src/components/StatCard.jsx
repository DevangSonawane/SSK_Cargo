import { TrendingUp, TrendingDown } from 'lucide-react';

const variants = {
  primary:   { icon: 'bg-primary/10 text-primary',   border: 'border-t-primary' },
  success:   { icon: 'bg-tertiary/10 text-tertiary', border: 'border-t-tertiary' },
  warning:   { icon: 'bg-warning/10 text-warning',   border: 'border-t-warning' },
  secondary: { icon: 'bg-secondary/10 text-secondary', border: 'border-t-secondary' },
};

export default function StatCard({ title, value, icon: Icon, change, changeType, prefix = '', variant = 'primary' }) {
  const fmt = (val) => {
    if (typeof val === 'number' && val >= 10000000) return `${prefix}${(val/10000000).toFixed(2)}Cr`;
    if (typeof val === 'number' && val >= 100000)   return `${prefix}${(val/100000).toFixed(1)}L`;
    if (typeof val === 'number' && val >= 1000)     return `${prefix}${val.toLocaleString('en-IN')}`;
    return `${prefix}${val}`;
  };

  const v = variants[variant] || variants.primary;
  const isPos = changeType === 'positive';

  return (
    <div className={`stat-card border-t-4 ${v.border}`}>
      <div className="flex items-start justify-between mb-3">
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ${v.icon}`}>
          {Icon && <Icon size={20} />}
        </div>
        {change !== undefined && (
          <span className={`flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full ${isPos ? 'bg-tertiary/10 text-tertiary' : 'bg-danger/10 text-danger'}`}>
            {isPos ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
            {change}%
          </span>
        )}
      </div>
      <p className="text-sm font-medium text-neutral-500">{title}</p>
      <h3 className="text-2xl font-poppins font-bold text-secondary mt-1 tracking-tight">{fmt(value)}</h3>
      {change !== undefined && (
        <p className="text-xs text-neutral-400 mt-1">vs last month</p>
      )}
    </div>
  );
}
