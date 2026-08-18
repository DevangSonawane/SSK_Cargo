import { useEffect, useState } from 'react';
import { X, CheckCircle, AlertCircle, Info } from 'lucide-react';

const config = {
  success: { icon: CheckCircle, cls: 'bg-secondary border-tertiary/30 text-white', iconCls: 'text-tertiary' },
  error:   { icon: AlertCircle, cls: 'bg-secondary border-danger/30 text-white',   iconCls: 'text-danger' },
  info:    { icon: Info,        cls: 'bg-secondary border-primary/30 text-white',  iconCls: 'text-primary' },
};

export default function Toast({ message, type = 'success', onClose, duration = 3000, onClick }) {
  const [visible, setVisible] = useState(false);
  const { icon: Icon, cls, iconCls } = config[type] || config.info;

  useEffect(() => {
    const t1 = setTimeout(() => setVisible(true), 50);
    const t2 = setTimeout(() => { setVisible(false); setTimeout(onClose, 300); }, duration);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [duration, onClose]);

  return (
    <div
      onClick={onClick}
      className={`fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3.5 rounded-2xl border shadow-lg transition-all duration-300 ${cls} ${visible ? 'translate-y-0 opacity-100' : 'translate-y-4 opacity-0'} ${onClick ? 'cursor-pointer' : ''}`}
    >
      <Icon size={18} className={`flex-shrink-0 ${iconCls}`} />
      <span className="text-sm font-medium">{message}</span>
      <button onClick={(e) => { e.stopPropagation(); setVisible(false); setTimeout(onClose, 300); }} className="ml-2 opacity-60 hover:opacity-100 transition-opacity">
        <X size={15} />
      </button>
    </div>
  );
}
