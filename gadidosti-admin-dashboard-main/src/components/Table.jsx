import { useState, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Search } from 'lucide-react';

export default function Table({
  columns, data, searchable = false, searchKeys = [],
  itemsPerPage = 10, loading = false,
  emptyMessage = 'No data available', actions = null,
}) {
  const [page, setPage] = useState(1);
  const [term, setTerm] = useState('');

  const filtered = useMemo(() => {
    if (!searchable || !term || !searchKeys.length) return data;
    const t = term.toLowerCase();
    return data.filter(row => searchKeys.some(k => row[k] && String(row[k]).toLowerCase().includes(t)));
  }, [data, term, searchable, searchKeys]);

  const total = Math.ceil(filtered.length / itemsPerPage);
  const start = (page - 1) * itemsPerPage;
  const rows = filtered.slice(start, start + itemsPerPage);
  const changePage = (p) => { if (p >= 1 && p <= total) setPage(p); };

  const pages = () => {
    if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1);
    if (page <= 3) return [1, 2, 3, 4, '...', total];
    if (page >= total - 2) return [1, '...', total-3, total-2, total-1, total];
    return [1, '...', page-1, page, page+1, '...', total];
  };

  if (loading) {
    return (
      <div className="space-y-2 p-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="skeleton h-12 w-full" />
        ))}
      </div>
    );
  }

  if (!data.length) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <div className="w-14 h-14 bg-neutral-100 rounded-2xl flex items-center justify-center mb-3">
          <Search size={22} className="text-neutral-400" />
        </div>
        <p className="text-neutral-600 font-semibold">{emptyMessage}</p>
        <p className="text-neutral-400 text-sm mt-1">Try adjusting your filters</p>
      </div>
    );
  }

  return (
    <div>
      {searchable && (
        <div className="mb-4 relative max-w-xs">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            type="text" placeholder="Search..." value={term}
            onChange={(e) => { setTerm(e.target.value); setPage(1); }}
            className="form-input pl-10"
          />
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="data-table">
          <thead>
            <tr>
              {columns.map(col => (
                <th key={col.key} className={col.className || ''} style={{ width: col.width }}>{col.label}</th>
              ))}
              {actions && <th className="w-24 text-center">Actions</th>}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr key={row.id || i}>
                {columns.map(col => (
                  <td key={col.key} className={col.className || ''}>
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </td>
                ))}
                {actions && <td className="text-center">{actions(row)}</td>}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {total > 1 && (
        <div className="flex items-center justify-between mt-5 px-1">
          <p className="text-sm text-neutral-500">
            Showing <span className="font-medium text-neutral-700">{start + 1}–{Math.min(start + itemsPerPage, filtered.length)}</span> of <span className="font-medium text-neutral-700">{filtered.length}</span>
          </p>
          <div className="flex items-center gap-1">
            <button onClick={() => changePage(page - 1)} disabled={page === 1}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-neutral-500 hover:bg-neutral-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors">
              <ChevronLeft size={16} />
            </button>
            {pages().map((p, i) => p === '...'
              ? <span key={`e${i}`} className="w-8 h-8 flex items-center justify-center text-neutral-400 text-sm">…</span>
              : <button key={p} onClick={() => changePage(p)}
                  className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${page === p ? 'bg-primary text-white shadow-sm' : 'text-neutral-600 hover:bg-neutral-100'}`}>
                  {p}
                </button>
            )}
            <button onClick={() => changePage(page + 1)} disabled={page === total}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-neutral-500 hover:bg-neutral-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors">
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
