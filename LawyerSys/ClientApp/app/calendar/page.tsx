"use client";

import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  Typography,
} from '@mui/material';
import api from '../../src/services/api';

type CalendarEvent = {
  id: string;
  type: string;
  title: string;
  start: string;
  end?: string;
  notes?: string;
  caseCode?: number;
  entityId?: number;
  isReminderEvent: boolean;
};

const toDateOnly = (d: Date) => d.toISOString().slice(0, 10);

export default function CalendarPage() {
  const [view, setView] = useState<'month' | 'week'>('month');
  const [anchorDate, setAnchorDate] = useState(new Date());
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [error, setError] = useState('');

  const range = useMemo(() => {
    const base = new Date(anchorDate);
    if (view === 'week') {
      const start = new Date(base);
      start.setDate(base.getDate() - base.getDay());
      const end = new Date(start);
      end.setDate(start.getDate() + 6);
      return { from: start, to: end };
    }

    const start = new Date(base.getFullYear(), base.getMonth(), 1);
    const end = new Date(base.getFullYear(), base.getMonth() + 1, 0);
    return { from: start, to: end };
  }, [anchorDate, view]);

  const groupedByDate = useMemo(() => {
    const map = new Map<string, CalendarEvent[]>();
    for (const event of events) {
      const key = event.start.slice(0, 10);
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(event);
    }

    return Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [events]);

  useEffect(() => {
    (async () => {
      setError('');
      try {
        const response = await api.get('/Calendar/events', {
          params: {
            fromDate: toDateOnly(range.from),
            toDate: toDateOnly(range.to),
          },
        });
        setEvents(response.data || []);
      } catch (err: any) {
        setError(err?.response?.data?.message || 'Failed to load calendar events');
      }
    })();
  }, [range.from, range.to]);

  return (
    <Box>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }}>
            <FormControl size="small" sx={{ minWidth: 180 }}>
              <InputLabel>View</InputLabel>
              <Select value={view} label="View" onChange={(e) => setView(e.target.value as 'month' | 'week')}>
                <MenuItem value="month">Monthly</MenuItem>
                <MenuItem value="week">Weekly</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 220 }}>
              <InputLabel>Month</InputLabel>
              <Select
                value={`${anchorDate.getFullYear()}-${anchorDate.getMonth()}`}
                label="Month"
                onChange={(e) => {
                  const [year, month] = String(e.target.value).split('-').map(Number);
                  setAnchorDate(new Date(year, month, 1));
                }}
              >
                {Array.from({ length: 12 }, (_, i) => {
                  const d = new Date(new Date().getFullYear(), i, 1);
                  return (
                    <MenuItem key={i} value={`${d.getFullYear()}-${d.getMonth()}`}>
                      {d.toLocaleString(undefined, { month: 'long', year: 'numeric' })}
                    </MenuItem>
                  );
                })}
              </Select>
            </FormControl>

            <Typography color="text.secondary">
              {range.from.toLocaleDateString()} - {range.to.toLocaleDateString()}
            </Typography>
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Stack spacing={1.5}>
        {groupedByDate.map(([date, dayEvents]) => (
          <Card key={date}>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 1 }}>{new Date(`${date}T00:00:00`).toDateString()}</Typography>
              <Stack spacing={1}>
                {dayEvents.sort((a, b) => a.start.localeCompare(b.start)).map((event) => (
                  <Box key={event.id} sx={{ p: 1.25, borderRadius: 1.5, border: '1px solid', borderColor: 'divider', bgcolor: event.isReminderEvent ? 'warning.50' : 'background.default' }}>
                    <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
                      <Chip size="small" label={event.type} color={event.isReminderEvent ? 'warning' : 'primary'} variant={event.isReminderEvent ? 'filled' : 'outlined'} />
                      <Typography variant="subtitle2">{event.title}</Typography>
                      <Typography variant="body2" color="text.secondary">{new Date(event.start).toLocaleTimeString()}</Typography>
                      {event.caseCode && <Chip size="small" variant="outlined" label={`Case #${event.caseCode}`} />}
                    </Stack>
                    {event.notes && <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>{event.notes}</Typography>}
                  </Box>
                ))}
              </Stack>
            </CardContent>
          </Card>
        ))}
      </Stack>

      {groupedByDate.length === 0 && <Typography color="text.secondary">No events in selected range.</Typography>}
    </Box>
  );
}
