"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import api from "../../../src/services/api";

type ThreadSummary = {
  caseCode: number;
  caseType: string;
  lastMessage: string;
  lastSenderName: string;
  lastSenderRole: string;
  lastMessageAtUtc?: string | null;
  unreadCount: number;
  waitingOnCustomer: boolean;
  hasAttachment: boolean;
};

type PortalOverview = {
  conversationThreads: ThreadSummary[];
  cases: { code: number; type: string }[];
};

type ConversationItem = {
  id: number;
  senderName: string;
  senderRole: string;
  message: string;
  attachmentFileId?: number | null;
  attachmentFileCode?: string;
  createdAtUtc: string;
  isMine: boolean;
  isReadByOtherParty: boolean;
};

type ThreadFilter = "all" | "unread" | "waiting";

export default function CustomerMessagesPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [threads, setThreads] = useState<ThreadSummary[]>([]);
  const [cases, setCases] = useState<{ code: number; type: string }[]>([]);
  const [selectedCaseCode, setSelectedCaseCode] = useState<number | "">("");
  const [conversation, setConversation] = useState<ConversationItem[]>([]);
  const [message, setMessage] = useState("");
  const [attachment, setAttachment] = useState<File | null>(null);
  const [search, setSearch] = useState("");
  const [threadFilter, setThreadFilter] = useState<ThreadFilter>("all");
  const [status, setStatus] = useState<{ type: "success" | "error"; message: string } | null>(null);

  async function loadOverview() {
    const response = await api.get<PortalOverview>("/ClientPortal/overview");
    const nextCases = Array.isArray(response.data?.cases) ? response.data.cases : [];
    const nextThreads = Array.isArray(response.data?.conversationThreads) ? response.data.conversationThreads : [];
    setCases(nextCases);
    setThreads(nextThreads);

    const queryCaseCode = Number(searchParams.get("caseCode") || "");
    const preferredCaseCode = Number.isFinite(queryCaseCode) && queryCaseCode > 0
      ? queryCaseCode
      : nextThreads[0]?.caseCode ?? nextCases[0]?.code ?? "";

    setSelectedCaseCode((current) => {
      if (current && (nextCases.some((item) => item.code === current) || nextThreads.some((item) => item.caseCode === current))) {
        return current;
      }

      return preferredCaseCode;
    });
  }

  async function loadConversation(caseCode: number) {
    const response = await api.get(`/cases/${caseCode}/conversation`);
    setConversation(Array.isArray(response.data) ? response.data : []);
  }

  useEffect(() => {
    void loadOverview().catch(() => setStatus({ type: "error", message: t("clientPortal.failedLoad") }));
  }, [searchParams, t]);

  useEffect(() => {
    if (!selectedCaseCode) {
      setConversation([]);
      return;
    }

    void loadConversation(Number(selectedCaseCode)).catch(() =>
      setStatus({ type: "error", message: t("cases.conversation.failedLoad", { defaultValue: "Failed to load conversation" }) })
    );
  }, [selectedCaseCode, t]);

  const filteredThreads = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();
    return threads.filter((item) => {
      if (threadFilter === "unread" && item.unreadCount === 0) {
        return false;
      }

      if (threadFilter === "waiting" && !item.waitingOnCustomer) {
        return false;
      }

      if (!normalizedSearch) {
        return true;
      }

      return `${item.caseCode} ${item.caseType} ${item.lastMessage} ${item.lastSenderName}`.toLowerCase().includes(normalizedSearch);
    });
  }, [search, threadFilter, threads]);

  async function sendMessage() {
    if (!selectedCaseCode || (!message.trim() && !attachment)) {
      return;
    }

    try {
      if (attachment) {
        const formData = new FormData();
        formData.append("message", message.trim());
        formData.append("attachment", attachment);
        await api.post(`/cases/${selectedCaseCode}/conversation/attachment`, formData, {
          headers: { "Content-Type": "multipart/form-data" },
        });
      } else {
        await api.post(`/cases/${selectedCaseCode}/conversation`, { message: message.trim() });
      }

      setMessage("");
      setAttachment(null);
      await Promise.all([loadConversation(Number(selectedCaseCode)), loadOverview()]);
      setStatus({ type: "success", message: t("cases.conversation.sent", { defaultValue: "Message sent" }) });
    } catch (err: any) {
      setStatus({
        type: "error",
        message: err?.response?.data?.message ?? t("cases.conversation.failedSend", { defaultValue: "Failed to send message" }),
      });
    }
  }

  return (
    <Box sx={{ p: 2 }}>
      {status ? <Alert severity={status.type} sx={{ mb: 2 }}>{status.message}</Alert> : null}

      <Card>
        <CardContent>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 2 }}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h5" sx={{ fontWeight: 800 }}>
                {t("clientPortal.messagesPageTitle", { defaultValue: "Messages with the office" })}
              </Typography>
              <Typography color="text.secondary">
                {t("clientPortal.messagesPageSubtitle", { defaultValue: "Choose a case to review updates and reply directly to the office." })}
              </Typography>
            </Box>
            <Button variant="outlined" onClick={() => router.push("/client-portal")}>
              {t("app.back", { defaultValue: "Back" })}
            </Button>
          </Stack>

          <Stack direction={{ xs: "column", lg: "row" }} spacing={2}>
            <Stack spacing={1.5} sx={{ width: { xs: "100%", lg: 360 }, flexShrink: 0 }}>
              <TextField
                size="small"
                label={t("common.search", { defaultValue: "Search" })}
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
              <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap" }}>
                <Chip
                  clickable
                  color={threadFilter === "all" ? "primary" : "default"}
                  label={t("clientPortal.inboxFilterAll", { defaultValue: "All" })}
                  onClick={() => setThreadFilter("all")}
                />
                <Chip
                  clickable
                  color={threadFilter === "unread" ? "primary" : "default"}
                  label={t("clientPortal.inboxFilterUnread", { defaultValue: "Unread" })}
                  onClick={() => setThreadFilter("unread")}
                />
                <Chip
                  clickable
                  color={threadFilter === "waiting" ? "primary" : "default"}
                  label={t("clientPortal.inboxFilterWaiting", { defaultValue: "Needs my reply" })}
                  onClick={() => setThreadFilter("waiting")}
                />
              </Stack>

              <Stack spacing={1} sx={{ maxHeight: 520, overflowY: "auto" }}>
                {filteredThreads.length === 0 ? (
                  <Typography color="text.secondary">
                    {t("clientPortal.noMessagesYet", { defaultValue: "No messages yet." })}
                  </Typography>
                ) : filteredThreads.map((item) => (
                  <Box
                    key={item.caseCode}
                    sx={{
                      p: 1.5,
                      borderRadius: 2,
                      border: "1px solid",
                      borderColor: selectedCaseCode === item.caseCode ? "primary.main" : "divider",
                      bgcolor: selectedCaseCode === item.caseCode ? "action.selected" : "background.paper",
                      cursor: "pointer",
                    }}
                    onClick={() => setSelectedCaseCode(item.caseCode)}
                  >
                    <Stack direction="row" spacing={1} sx={{ alignItems: "center", justifyContent: "space-between", mb: 0.5 }}>
                      <Typography variant="subtitle2">#{item.caseCode} - {item.caseType}</Typography>
                      {item.unreadCount > 0 ? (
                        <Chip size="small" color="primary" label={t("clientPortal.unreadCount", { defaultValue: "{{count}} unread", count: item.unreadCount })} />
                      ) : null}
                    </Stack>
                    <Typography variant="body2" color="text.secondary">
                      {item.lastMessage || t("clientPortal.noMessagesYet", { defaultValue: "No messages yet." })}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {item.lastSenderName
                        ? `${item.lastSenderName} - ${item.lastSenderRole}`
                        : t("clientPortal.awaitingFirstMessage", { defaultValue: "Start the conversation from the inbox." })}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            </Stack>

            <Box sx={{ flexGrow: 1 }}>
              <TextField
                select
                fullWidth
                label={t("clientPortal.selectCase", { defaultValue: "Select Case" })}
                value={selectedCaseCode}
                onChange={(event) => setSelectedCaseCode(Number(event.target.value))}
                sx={{ mb: 2 }}
              >
                {cases.map((item) => (
                  <MenuItem key={item.code} value={item.code}>
                    #{item.code} - {item.type}
                  </MenuItem>
                ))}
              </TextField>

              <Stack spacing={1.25} sx={{ maxHeight: 420, overflowY: "auto", mb: 2 }}>
                {conversation.length === 0 ? (
                  <Typography color="text.secondary">
                    {t("cases.conversation.empty", { defaultValue: "No conversation messages yet." })}
                  </Typography>
                ) : conversation.map((item) => (
                  <Box
                    key={item.id}
                    sx={{
                      alignSelf: item.isMine ? "flex-end" : "flex-start",
                      maxWidth: "80%",
                      px: 1.5,
                      py: 1.25,
                      borderRadius: 2,
                      bgcolor: item.isMine ? "primary.main" : "action.hover",
                      color: item.isMine ? "primary.contrastText" : "text.primary",
                    }}
                  >
                    <Typography variant="caption" sx={{ display: "block", opacity: 0.8 }}>
                      {item.senderName} - {item.senderRole} - {new Date(item.createdAtUtc).toLocaleString()}
                    </Typography>
                    <Typography variant="body2" sx={{ whiteSpace: "pre-wrap" }}>{item.message}</Typography>
                    {item.attachmentFileId ? (
                      <Button size="small" component="a" href={`/api/files/${item.attachmentFileId}/download`} target="_blank" sx={{ mt: 1 }}>
                        {item.attachmentFileCode || t("cases.conversation.attachment", { defaultValue: "Attachment" })}
                      </Button>
                    ) : null}
                    {item.isMine ? (
                      <Typography variant="caption" sx={{ display: "block", mt: 0.5 }}>
                        {item.isReadByOtherParty
                          ? t("cases.conversation.read", { defaultValue: "Seen" })
                          : t("cases.conversation.unread", { defaultValue: "Waiting for review" })}
                      </Typography>
                    ) : null}
                  </Box>
                ))}
              </Stack>

              <TextField
                fullWidth
                multiline
                minRows={4}
                label={t("cases.conversation.message", { defaultValue: "Message" })}
                value={message}
                onChange={(event) => setMessage(event.target.value)}
              />
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5} sx={{ mt: 1.5 }}>
                <Button variant="outlined" component="label">
                  {attachment
                    ? `${t("cases.conversation.attachmentSelected", { defaultValue: "Attachment selected" })}: ${attachment.name}`
                    : t("cases.conversation.attach", { defaultValue: "Attach file" })}
                  <input hidden type="file" onChange={(event) => setAttachment(event.target.files?.[0] ?? null)} />
                </Button>
                <Button variant="contained" onClick={sendMessage} disabled={!selectedCaseCode || (!message.trim() && !attachment)}>
                  {t("cases.conversation.send", { defaultValue: "Send message" })}
                </Button>
              </Stack>
            </Box>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
