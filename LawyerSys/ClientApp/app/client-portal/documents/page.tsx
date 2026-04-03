"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import api from "../../../src/services/api";

type PortalResponse = {
  cases: { code: number; type: string }[];
  documents: { id: number; type: string; number: number; details: string }[];
  caseFiles: { fileId: number; caseCode: number; fileCode: string; filePath: string }[];
  requestedDocuments: { id: number; caseCode: number; title: string; status: string; uploadedFileId?: number | null; uploadedFileCode: string }[];
};

export default function CustomerDocumentsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const [data, setData] = useState<PortalResponse | null>(null);
  const [selectedCaseCode, setSelectedCaseCode] = useState<number | "">("");
  const [status, setStatus] = useState<{ type: "success" | "error"; message: string } | null>(null);
  const uploadInputRef = useRef<HTMLInputElement | null>(null);

  const load = useCallback(async () => {
    const response = await api.get("/ClientPortal/overview");
    setData(response.data);
    if (!selectedCaseCode && Array.isArray(response.data?.cases) && response.data.cases.length > 0) {
      setSelectedCaseCode(response.data.cases[0].code);
    }
  }, [selectedCaseCode]);

  useEffect(() => {
    void load().catch(() => setStatus({ type: "error", message: t("clientPortal.failedLoad") }));
  }, [load, t]);

  async function uploadFile(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file || !selectedCaseCode) return;

    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("title", file.name);
      await api.post(`/ClientPortal/cases/${selectedCaseCode}/files`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      setStatus({ type: "success", message: t("clientPortal.uploadSuccess", { defaultValue: "File uploaded successfully" }) });
      await load();
    } catch (err: any) {
      setStatus({ type: "error", message: err?.response?.data?.message ?? t("clientPortal.uploadFailed", { defaultValue: "Failed to upload file" }) });
    }
  }

  const currentCaseFiles = (data?.caseFiles || []).filter((item) => !selectedCaseCode || item.caseCode === selectedCaseCode);
  const currentRequestedDocuments = (data?.requestedDocuments || []).filter((item) => !selectedCaseCode || item.caseCode === selectedCaseCode);

  return (
    <Box sx={{ p: 2 }}>
      {status ? <Alert severity={status.type} sx={{ mb: 2 }}>{status.message}</Alert> : null}

      <Card>
        <CardContent>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mb: 2 }}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h5" sx={{ fontWeight: 800 }}>
                {t("clientPortal.documentsPageTitle", { defaultValue: "My case documents" })}
              </Typography>
              <Typography color="text.secondary">
                {t("clientPortal.documentsPageSubtitle", { defaultValue: "Review office documents, requested uploads, and files you have already shared." })}
              </Typography>
            </Box>
            <Button variant="outlined" onClick={() => router.push("/client-portal")}>
              {t("app.back", { defaultValue: "Back" })}
            </Button>
          </Stack>

          <Stack direction={{ xs: "column", md: "row" }} spacing={1.5} sx={{ mb: 2 }}>
            <TextField
              select
              fullWidth
              label={t("clientPortal.selectCase", { defaultValue: "Select Case" })}
              value={selectedCaseCode}
              onChange={(event) => setSelectedCaseCode(Number(event.target.value))}
            >
              {(data?.cases || []).map((item) => (
                <MenuItem key={item.code} value={item.code}>
                  #{item.code} - {item.type}
                </MenuItem>
              ))}
            </TextField>
            <Button variant="contained" onClick={() => uploadInputRef.current?.click()} disabled={!selectedCaseCode}>
              {t("clientPortal.uploadCaseFile", { defaultValue: "Upload File" })}
            </Button>
            <input ref={uploadInputRef} type="file" hidden onChange={uploadFile} />
          </Stack>

          <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.requestedDocumentsTitle", { defaultValue: "Requested Documents" })}</Typography>
          <Table size="small" sx={{ mb: 3 }}>
            <TableHead>
              <TableRow>
                <TableCell>{t("clientPortal.type")}</TableCell>
                <TableCell>{t("clientPortal.status")}</TableCell>
                <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {currentRequestedDocuments.length === 0 ? (
                <TableRow><TableCell colSpan={3}>{t("clientPortal.noRequestedDocuments", { defaultValue: "The office has not requested any documents from you yet." })}</TableCell></TableRow>
              ) : currentRequestedDocuments.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{item.title}</TableCell>
                  <TableCell>{item.status}</TableCell>
                  <TableCell>
                    {item.uploadedFileId ? (
                      <Button size="small" component="a" href={`/api/files/${item.uploadedFileId}/download`} target="_blank">
                        {item.uploadedFileCode || t("clientPortal.download", { defaultValue: "Download" })}
                      </Button>
                    ) : (
                      <Button size="small" onClick={() => router.push(`/cases/${item.caseCode}`)}>
                        {t("clientPortal.openCase", { defaultValue: "Open case" })}
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.caseFiles", { defaultValue: "Case Files" })}</Typography>
          <Table size="small" sx={{ mb: 3 }}>
            <TableHead>
              <TableRow>
                <TableCell>{t("clientPortal.case")}</TableCell>
                <TableCell>{t("clientPortal.fileName", { defaultValue: "File" })}</TableCell>
                <TableCell>{t("clientPortal.actions", { defaultValue: "Actions" })}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {currentCaseFiles.length === 0 ? (
                <TableRow><TableCell colSpan={3}>{t("clientPortal.noCaseFiles", { defaultValue: "No files are available for your cases yet." })}</TableCell></TableRow>
              ) : currentCaseFiles.map((item) => (
                <TableRow key={`${item.caseCode}-${item.fileId}`}>
                  <TableCell>{item.caseCode}</TableCell>
                  <TableCell>{item.fileCode || item.filePath}</TableCell>
                  <TableCell>
                    <Button size="small" component="a" href={`/api/files/${item.fileId}/download`} target="_blank">
                      {t("clientPortal.download", { defaultValue: "Download" })}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          <Typography variant="h6" sx={{ mb: 1 }}>{t("clientPortal.myDocuments")}</Typography>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>#</TableCell>
                <TableCell>{t("clientPortal.type")}</TableCell>
                <TableCell>{t("clientPortal.details")}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.documents || []).length === 0 ? (
                <TableRow><TableCell colSpan={3}>{t("clientPortal.noDocuments", { defaultValue: "No judicial documents are available for you yet." })}</TableCell></TableRow>
              ) : data?.documents.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{item.number}</TableCell>
                  <TableCell>{item.type}</TableCell>
                  <TableCell>{item.details}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
}
