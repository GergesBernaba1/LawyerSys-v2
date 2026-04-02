"use client";

import React, { useEffect, useRef } from "react";
import { Box, Divider, IconButton, Stack, Tooltip } from "@mui/material";
import {
  FormatBold,
  FormatItalic,
  FormatUnderlined,
  FormatListBulleted,
  FormatListNumbered,
  Undo,
  Redo,
  HorizontalRule,
} from "@mui/icons-material";

type HtmlEditorProps = {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  minHeight?: number;
};

export default function HtmlEditor({
  value,
  onChange,
  placeholder,
  minHeight = 320,
}: HtmlEditorProps) {
  const editorRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const editor = editorRef.current;
    if (!editor) {
      return;
    }

    if (editor.innerHTML !== value) {
      editor.innerHTML = value || "";
    }
  }, [value]);

  function emitChange() {
    const editor = editorRef.current;
    if (!editor) {
      return;
    }

    onChange(editor.innerHTML);
  }

  function exec(command: string, arg?: string) {
    const editor = editorRef.current;
    if (!editor) {
      return;
    }

    editor.focus();
    document.execCommand(command, false, arg);
    emitChange();
  }

  return (
    <Box sx={{ border: "1px solid", borderColor: "divider", borderRadius: 2, overflow: "hidden" }}>
      <Stack direction="row" spacing={0.5} sx={{ p: 1, bgcolor: "action.hover", alignItems: "center", flexWrap: "wrap" }}>
        <Tooltip title="Bold">
          <IconButton size="small" onClick={() => exec("bold")}>
            <FormatBold fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Italic">
          <IconButton size="small" onClick={() => exec("italic")}>
            <FormatItalic fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Underline">
          <IconButton size="small" onClick={() => exec("underline")}>
            <FormatUnderlined fontSize="small" />
          </IconButton>
        </Tooltip>
        <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />
        <Tooltip title="Bulleted list">
          <IconButton size="small" onClick={() => exec("insertUnorderedList")}>
            <FormatListBulleted fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Numbered list">
          <IconButton size="small" onClick={() => exec("insertOrderedList")}>
            <FormatListNumbered fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Horizontal line">
          <IconButton size="small" onClick={() => exec("insertHorizontalRule")}>
            <HorizontalRule fontSize="small" />
          </IconButton>
        </Tooltip>
        <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />
        <Tooltip title="Undo">
          <IconButton size="small" onClick={() => exec("undo")}>
            <Undo fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Redo">
          <IconButton size="small" onClick={() => exec("redo")}>
            <Redo fontSize="small" />
          </IconButton>
        </Tooltip>
      </Stack>

      <Box
        ref={editorRef}
        contentEditable
        suppressContentEditableWarning
        onInput={emitChange}
        onBlur={emitChange}
        data-placeholder={placeholder || ""}
        sx={{
          minHeight,
          p: 2,
          outline: "none",
          lineHeight: 1.7,
          fontSize: "0.95rem",
          "&:empty::before": {
            content: "attr(data-placeholder)",
            color: "text.secondary",
          },
        }}
      />
    </Box>
  );
}

