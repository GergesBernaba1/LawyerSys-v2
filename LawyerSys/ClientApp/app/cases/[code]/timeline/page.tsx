"use client";

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
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
import { ArrowBack } from '@mui/icons-material';
import api from '../../../../src/services/api';

type TimelineEvent = {
  category: string;
  occurredAt: string;
  title: string;
  description?: string;
  entityId?: number;
};

type TimelineResponse = {
  caseCode: number;
  caseType: string;
  events: TimelineEvent[];
};

export default function CaseTimelinePage() {
  const params = useParams() as { code?: string } | undefined;
  const code = Number(params?.code || 0);
  const router = useRouter();
  const [timeline, setTimeline] = useState<TimelineResponse | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!code) return;
    (async () => {
      setError('');
      try {
        const response = await api.get(`/Cases/${code}/timeline`);
        setTimeline(response.data);
      } catch (err: any) {
        setError(err?.response?.data?.message || 'Failed to load timeline');
      }
    })();
  }, [code]);

  return (
    <Box>
      <Button startIcon={<ArrowBack />} onClick={() => router.push(`/cases/${code}`)} sx={{ mb: 2 }}>
        Back to case
      </Button>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h5">Case #{timeline?.caseCode || code} Timeline</Typography>
          {timeline?.caseType && <Typography color="text.secondary">Type: {timeline.caseType}</Typography>}
        </CardContent>
      </Card>

      <Stack spacing={1.5}>
        {(timeline?.events || []).map((event, index) => (
          <Card key={`${event.category}-${event.entityId ?? index}-${event.occurredAt}`}>
            <CardContent>
              <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap">
                <Chip size="small" label={event.category} variant="outlined" />
                <Typography variant="subtitle1">{event.title}</Typography>
                <Typography variant="body2" color="text.secondary">{new Date(event.occurredAt).toLocaleString()}</Typography>
              </Stack>
              {event.description && <Typography variant="body2" color="text.secondary" sx={{ mt: 0.75 }}>{event.description}</Typography>}
            </CardContent>
          </Card>
        ))}
      </Stack>

      {(timeline?.events?.length || 0) === 0 && <Typography color="text.secondary">No timeline events found.</Typography>}
    </Box>
  );
}
