"use client";

import React, { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemText,
  Paper,
  Stack,
  Typography,
} from "@mui/material";
import {
  AssignmentTurnedIn as TaskIcon,
  Event as EventIcon,
  Notifications as NotificationsIcon,
  FactCheck as IntakeIcon,
  Timer as TimerIcon,
} from "@mui/icons-material";
import { useTranslation } from "react-i18next";
import { useRouter } from "next/navigation";
import api from "../../src/services/api";
import { useAuth } from "../../src/services/auth";

type TaskItem = {
  id: number;
  taskName?: string;
  taskReminderDate?: string;
  notes?: string;
};

type LeadItem = {
  id: number;
  fullName?: string;
  subject?: string;
  status?: string;
  nextFollowUpAt?: string | null;
};

type CalendarEvent = {
  id: string;
  type: string;
  title: string;
  start: string;
  caseCode?: number;
  isReminderEvent: boolean;
};

type TimeEntry = {
  id: number;
  workType: string;
  startedAt: string;
  caseCode?: number | null;
  durationMinutes: number;
  status: string;
};

type NotificationItem = {
  id: number;
  title: string;
  message: string;
  route?: string | null;
  timestamp: string;
  category?: string;
};

const toDateOnly = (date: Date) => date.toISOString().slice(0, 10);

function SectionCard({
  title,
  icon,
  actionHref,
  actionLabel,
  children,
}: {
  title: string;
  icon: React.ReactNode;
  actionHref: string;
  actionLabel: string;
  children: React.ReactNode;
}) {
  return (
    <Paper elevation={0} sx={{ p: 3, borderRadius: 4, border: "1px solid", borderColor: "divider", height: "100%" }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Stack direction="row" spacing={1.25} alignItems="center">
          {icon}
          <Typography variant="h6" sx={{ fontWeight: 800 }}>
            {title}
          </Typography>
        </Stack>
        <Button component={Link} href={actionHref} size="small" sx={{ fontWeight: 700 }}>
          {actionLabel}
        </Button>
      </Box>
      {children}
    </Paper>
  );
}

export default function EmployeeWorkQueuePage() {
  const { t, i18n } = useTranslation();
  const router = useRouter();
  const { hasRole } = useAuth();
  const isEmployeeOnly = hasRole("Employee") && !hasRole("Admin") && !hasRole("SuperAdmin");
  const locale = i18n.resolvedLanguage?.startsWith("ar") ? "ar-EG" : "en-US";

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [overdueTasks, setOverdueTasks] = useState<TaskItem[]>([]);
  const [followUps, setFollowUps] = useState<LeadItem[]>([]);
  const [todayEvents, setTodayEvents] = useState<CalendarEvent[]>([]);
  const [runningTimers, setRunningTimers] = useState<TimeEntry[]>([]);
  const [unreadNotifications, setUnreadNotifications] = useState<NotificationItem[]>([]);

  useEffect(() => {
    if (!isEmployeeOnly) {
      router.replace("/dashboard");
    }
  }, [isEmployeeOnly, router]);

  useEffect(() => {
    if (!isEmployeeOnly) {
      return;
    }

    const load = async () => {
      setLoading(true);
      setError("");
      const today = new Date();
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      try {
        const [tasksRes, intakeRes, calendarRes, timeRes, notificationRes] = await Promise.all([
          api.get("/AdminTasks?page=1&pageSize=100"),
          api.get("/Intake"),
          api.get("/Calendar/events", {
            params: {
              fromDate: toDateOnly(today),
              toDate: toDateOnly(tomorrow),
            },
          }),
          api.get("/TimeTracking", { params: { status: "Running" } }),
          api.get("/Notifications", { params: { page: 1, pageSize: 8, filter: "Unread" } }),
        ]);

        const tasks = Array.isArray(tasksRes.data) ? tasksRes.data : tasksRes.data?.items || [];
        const leads = intakeRes.data || [];
        const events = calendarRes.data || [];
        const timers = timeRes.data || [];
        const notifications = notificationRes.data?.items || [];
        const now = new Date();

        setOverdueTasks(
          tasks
            .filter((item: TaskItem) => item.taskReminderDate && new Date(item.taskReminderDate) < now)
            .sort((a: TaskItem, b: TaskItem) => new Date(a.taskReminderDate || "").getTime() - new Date(b.taskReminderDate || "").getTime())
            .slice(0, 6)
        );
        setFollowUps(
          leads
            .filter((item: LeadItem) => item.nextFollowUpAt)
            .sort((a: LeadItem, b: LeadItem) => new Date(a.nextFollowUpAt || "").getTime() - new Date(b.nextFollowUpAt || "").getTime())
            .slice(0, 6)
        );
        setTodayEvents(
          events
            .sort((a: CalendarEvent, b: CalendarEvent) => a.start.localeCompare(b.start))
            .slice(0, 8)
        );
        setRunningTimers(timers.slice(0, 6));
        setUnreadNotifications(notifications);
      } catch (err: any) {
        setError(err?.response?.data?.message || t("employeeWorkQueue.failedLoad", { defaultValue: "Failed to load your work queue." }));
      } finally {
        setLoading(false);
      }
    };

    void load();
  }, [isEmployeeOnly, t]);

  const totalItems = useMemo(
    () => overdueTasks.length + followUps.length + todayEvents.length + runningTimers.length + unreadNotifications.length,
    [overdueTasks, followUps, todayEvents, runningTimers, unreadNotifications]
  );

  if (!isEmployeeOnly) {
    return null;
  }

  return (
    <Box sx={{ pb: 4 }}>
      <Paper elevation={0} sx={{ p: { xs: 2.5, md: 3 }, mb: 3, borderRadius: 4, border: "1px solid", borderColor: "divider" }}>
        <Typography variant="h5" sx={{ fontWeight: 800 }}>
          {t("employeeWorkQueue.title", { defaultValue: "My Work Queue" })}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {t("employeeWorkQueue.subtitle", { defaultValue: "Everything that currently needs your attention in one place." })}
        </Typography>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ mt: 2 }}>
          <Chip color="primary" label={t("employeeWorkQueue.totalOpen", { defaultValue: "Open queue items" }) + `: ${totalItems}`} />
          <Chip variant="outlined" label={t("employeeWorkQueue.todayFocus", { defaultValue: "Today focus" }) + `: ${todayEvents.length}`} />
        </Stack>
      </Paper>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {loading && <Alert severity="info" sx={{ mb: 2 }}>{t("app.loading", { defaultValue: "Loading..." })}</Alert>}

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", xl: "repeat(2, 1fr)" }, gap: 3 }}>
        <SectionCard
          title={t("employeeWorkQueue.overdueTasks", { defaultValue: "My Overdue Tasks" })}
          icon={<TaskIcon color="error" />}
          actionHref="/tasks"
          actionLabel={t("app.viewAll", { defaultValue: "View all" })}
        >
          {overdueTasks.length > 0 ? (
            <List disablePadding>
              {overdueTasks.map((task, index) => (
                <React.Fragment key={task.id}>
                  <ListItem disablePadding sx={{ py: 1.25 }}>
                    <ListItemText
                      primary={task.taskName || t("tasks.task", { defaultValue: "Task" })}
                      secondary={`${new Date(task.taskReminderDate || "").toLocaleString(locale)}${task.notes ? ` • ${task.notes}` : ""}`}
                    />
                  </ListItem>
                  {index < overdueTasks.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">{t("employeeWorkQueue.noneOverdue", { defaultValue: "No overdue tasks assigned to you." })}</Typography>
          )}
        </SectionCard>

        <SectionCard
          title={t("employeeWorkQueue.followUps", { defaultValue: "My Follow-ups" })}
          icon={<IntakeIcon color="warning" />}
          actionHref="/intake"
          actionLabel={t("app.viewAll", { defaultValue: "View all" })}
        >
          {followUps.length > 0 ? (
            <List disablePadding>
              {followUps.map((lead, index) => (
                <React.Fragment key={lead.id}>
                  <ListItem disablePadding sx={{ py: 1.25 }}>
                    <ListItemText
                      primary={lead.fullName || lead.subject || t("employeeWorkQueue.lead", { defaultValue: "Lead" })}
                      secondary={`${lead.subject || "-"} • ${lead.nextFollowUpAt ? new Date(lead.nextFollowUpAt).toLocaleString(locale) : "-"}`}
                    />
                    <Chip size="small" label={lead.status || t("common.pending", { defaultValue: "Pending" })} />
                  </ListItem>
                  {index < followUps.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">{t("employeeWorkQueue.noneFollowUps", { defaultValue: "No follow-ups are scheduled right now." })}</Typography>
          )}
        </SectionCard>

        <SectionCard
          title={t("employeeWorkQueue.todayHearings", { defaultValue: "Today and Upcoming Hearings" })}
          icon={<EventIcon color="primary" />}
          actionHref="/calendar"
          actionLabel={t("app.viewAll", { defaultValue: "View all" })}
        >
          {todayEvents.length > 0 ? (
            <List disablePadding>
              {todayEvents.map((event, index) => (
                <React.Fragment key={event.id}>
                  <ListItem disablePadding sx={{ py: 1.25 }}>
                    <ListItemText
                      primary={event.title}
                      secondary={new Date(event.start).toLocaleString(locale)}
                    />
                    {event.caseCode && (
                      <Button component={Link} href={`/cases/${event.caseCode}`} size="small">
                        {t("cases.details", { defaultValue: "Details" })}
                      </Button>
                    )}
                  </ListItem>
                  {index < todayEvents.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">{t("employeeWorkQueue.noneHearings", { defaultValue: "No hearings or reminders in the selected window." })}</Typography>
          )}
        </SectionCard>

        <SectionCard
          title={t("employeeWorkQueue.runningTimers", { defaultValue: "Running Timers" })}
          icon={<TimerIcon color="success" />}
          actionHref="/timetracking"
          actionLabel={t("app.viewAll", { defaultValue: "View all" })}
        >
          {runningTimers.length > 0 ? (
            <List disablePadding>
              {runningTimers.map((entry, index) => (
                <React.Fragment key={entry.id}>
                  <ListItem disablePadding sx={{ py: 1.25 }}>
                    <ListItemText
                      primary={entry.workType}
                      secondary={`${new Date(entry.startedAt).toLocaleString(locale)} • ${entry.durationMinutes} ${t("timetracking.minutes", { defaultValue: "minutes" })}`}
                    />
                    {entry.caseCode && <Chip size="small" label={`#${entry.caseCode}`} />}
                  </ListItem>
                  {index < runningTimers.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">{t("employeeWorkQueue.noneTimers", { defaultValue: "No timers are currently running." })}</Typography>
          )}
        </SectionCard>

        <SectionCard
          title={t("employeeWorkQueue.unreadUpdates", { defaultValue: "Unread Updates" })}
          icon={<NotificationsIcon color="info" />}
          actionHref="/dashboard"
          actionLabel={t("app.viewAll", { defaultValue: "View all" })}
        >
          {unreadNotifications.length > 0 ? (
            <List disablePadding>
              {unreadNotifications.map((notification, index) => (
                <React.Fragment key={notification.id}>
                  <ListItem disablePadding sx={{ py: 1.25 }}>
                    <ListItemText
                      primary={notification.title}
                      secondary={`${notification.message} • ${new Date(notification.timestamp).toLocaleString(locale)}`}
                    />
                    {notification.route && (
                      <Button component={Link} href={notification.route} size="small">
                        {t("app.open", { defaultValue: "Open" })}
                      </Button>
                    )}
                  </ListItem>
                  {index < unreadNotifications.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          ) : (
            <Typography color="text.secondary">{t("employeeWorkQueue.noneNotifications", { defaultValue: "No unread employee updates right now." })}</Typography>
          )}
        </SectionCard>
      </Box>
    </Box>
  );
}
