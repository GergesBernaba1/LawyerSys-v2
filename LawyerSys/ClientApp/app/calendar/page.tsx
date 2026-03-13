"use client";

import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Stack,
  Typography,
} from '@mui/material';
import { useTranslation } from 'react-i18next';
import { useRouter } from 'next/navigation';
import api from '../../src/services/api';
import SearchableSelect from '../../src/components/SearchableSelect';
import { useAuth } from '../../src/services/auth';

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
  const { t } = useTranslation();
  const router = useRouter();
  const { hasRole } = useAuth();
  const isEmployeeOnly = hasRole('Employee') && !hasRole('Admin') && !hasRole('SuperAdmin');
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
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            {isEmployeeOnly ? t('calendar.employeeTitle', { defaultValue: 'My Calendar' }) : t('app.calendar', { defaultValue: 'Calendar' })}
          </Typography>
          <Typography color="text.secondary">
            {isEmployeeOnly
              ? t('calendar.employeeSubtitle', { defaultValue: 'Assigned hearings, reminders, and task dates for your workload.' })
              : t('calendar.subtitle', { defaultValue: 'Events, hearings, reminders, and task dates.' })}
          </Typography>
        </CardContent>
      </Card>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ xs: 'stretch', md: 'center' }}>
            <SearchableSelect<'month' | 'week'>
              size="small"
              label={t('calendar.view', { defaultValue: 'View' })}
              value={view}
              onChange={(value) => setView((value ?? 'month') as 'month' | 'week')}
              options={[
                { value: 'month', label: t('calendar.monthly', { defaultValue: 'Monthly' }) as string },
                { value: 'week', label: t('calendar.weekly', { defaultValue: 'Weekly' }) as string },
              ]}
              disableClearable
              sx={{ minWidth: 180 }}
            />

            <SearchableSelect<string>
              size="small"
              label={t('calendar.month', { defaultValue: 'Month' })}
              value={`${anchorDate.getFullYear()}-${anchorDate.getMonth()}`}
              onChange={(value) => {
                const [year, month] = String(value ?? `${anchorDate.getFullYear()}-${anchorDate.getMonth()}`).split('-').map(Number);
                setAnchorDate(new Date(year, month, 1));
              }}
              options={Array.from({ length: 12 }, (_, i) => {
                const d = new Date(new Date().getFullYear(), i, 1);
                return {
                  value: `${d.getFullYear()}-${d.getMonth()}`,
                  label: d.toLocaleString(undefined, { month: 'long', year: 'numeric' }),
                };
              })}
              disableClearable
              sx={{ minWidth: 220 }}
            />

            <Typography color="text.secondary">
              {range.from.toLocaleDateString()} - {range.to.toLocaleDateString()}
            </Typography>
            <Stack direction="row" spacing={1}>
              <Button variant="outlined" size="small" onClick={() => { setView('week'); setAnchorDate(new Date()); }}>
                {t('calendar.today', { defaultValue: 'Today' })}
              </Button>
              <Button variant="outlined" size="small" onClick={() => { setView('week'); }}>
                {t('calendar.thisWeek', { defaultValue: 'This week' })}
              </Button>
              <Button variant="outlined" size="small" onClick={() => { setView('month'); }}>
                {t('calendar.thisMonth', { defaultValue: 'This month' })}
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {isEmployeeOnly && <Alert severity="info" sx={{ mb: 2 }}>{t('calendar.employeeHint', { defaultValue: 'Only your assigned hearings, reminders, and task dates are shown here.' })}</Alert>}

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
                      {event.caseCode && (
                        <Button size="small" onClick={() => router.push(`/cases/${event.caseCode}`)}>
                          {t('cases.caseCode', { defaultValue: 'Case code' })}: {event.caseCode}
                        </Button>
                      )}
                    </Stack>
                    {event.notes && <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>{event.notes}</Typography>}
                  </Box>
                ))}
              </Stack>
            </CardContent>
          </Card>
        ))}
      </Stack>

      {groupedByDate.length === 0 && <Typography color="text.secondary">{t('calendar.noEvents', { defaultValue: 'No events in selected range.' })}</Typography>}
    </Box>
  );
}
