import { useEffect, useRef, useState } from 'react';
import { io } from 'socket.io-client';
import { MessageCircle } from 'lucide-react';
import { api, getToken } from '../services/api';

const BASE = import.meta.env.VITE_API_URL || 'http://localhost:5000';

// Read-only live view of a booking's chat — admin can see the client/broker/driver
// conversation for support/dispute purposes, but never sends into it (enforced server-side
// too: chatService.canSend only allows actual booking participants).
export default function ChatWindow({ bookingId }) {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const socketRef = useRef(null);
  const bottomRef = useRef(null);

  useEffect(() => {
    if (!bookingId) return;
    let cancelled = false;
    const token = getToken();

    const init = async () => {
      setLoading(true);
      setLoadError(false);
      try {
        const threadRes = await api.get(`/api/chat/bookings/${bookingId}/thread`, token);
        if (!threadRes?.success) throw new Error(threadRes?.message);
        const thread = threadRes.data.thread;
        if (cancelled) return;

        const messagesRes = await api.get(`/api/chat/threads/${thread.id}/messages?limit=50`, token);
        if (!cancelled) setMessages(messagesRes.data?.messages || []);

        const socket = io(BASE, { auth: { token }, transports: ['websocket', 'polling'] });
        socketRef.current = socket;
        socket.emit('join-thread', { threadId: thread.id });
        socket.on('new-message', (msg) => {
          if (msg.threadId !== thread.id) return;
          setMessages((current) => (current.some((m) => m.id === msg.id) ? current : [...current, msg]));
        });
      } catch {
        if (!cancelled) setLoadError(true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    init();

    return () => {
      cancelled = true;
      socketRef.current?.disconnect();
      socketRef.current = null;
    };
  }, [bookingId]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="flex flex-col h-[480px]">
      <div className="flex items-center gap-1.5 text-xs text-neutral-400 mb-2">
        <MessageCircle size={12} /> Read-only — admin cannot send messages
      </div>
      <div className="flex-1 overflow-y-auto space-y-2.5 p-1 bg-neutral-50 rounded-xl">
        {loading ? (
          <div className="h-full flex items-center justify-center">
            <div className="w-6 h-6 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
          </div>
        ) : loadError ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <MessageCircle className="w-8 h-8 text-neutral-200 mb-2" />
            <p className="text-sm text-neutral-400">Couldn't load this chat.</p>
          </div>
        ) : messages.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <MessageCircle className="w-8 h-8 text-neutral-200 mb-2" />
            <p className="text-sm text-neutral-400">No messages yet.</p>
          </div>
        ) : (
          messages.map((m) => (
            <div key={m.id} className="px-3">
              <div className="flex items-center gap-2 mb-0.5">
                <span className="text-xs font-semibold text-neutral-700">{m.senderName}</span>
                <span className="text-[10px] text-neutral-400 uppercase">{m.senderRole}</span>
                <span className="text-[10px] text-neutral-300">{new Date(m.createdAt).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
              </div>
              <p className="text-sm text-neutral-700 bg-white rounded-lg px-3 py-2 inline-block shadow-sm">{m.message}</p>
            </div>
          ))
        )}
        <div ref={bottomRef} />
      </div>
    </div>
  );
}
