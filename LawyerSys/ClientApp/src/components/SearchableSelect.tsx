"use client";

import React from "react";
import {
  Autocomplete,
  CircularProgress,
  TextField,
  createFilterOptions,
  type AutocompleteProps,
  type SxProps,
  type Theme,
} from "@mui/material";

export type SearchableOption<T extends string | number = string | number> = {
  value: T;
  label: string;
  keywords?: string[];
  disabled?: boolean;
};

type SearchableSelectProps<T extends string | number> = {
  label: string;
  options: SearchableOption<T>[];
  value: T | null | undefined;
  onChange: (value: T | null) => void;
  disabled?: boolean;
  fullWidth?: boolean;
  required?: boolean;
  error?: boolean;
  helperText?: React.ReactNode;
  placeholder?: string;
  size?: "small" | "medium";
  disableClearable?: boolean;
  loading?: boolean;
  noOptionsText?: React.ReactNode;
  onOpen?: () => void;
  sx?: SxProps<Theme>;
};

const filterOptions = createFilterOptions<SearchableOption>({
  stringify: (option) => [option.label, ...(option.keywords ?? [])].join(" "),
  trim: true,
});

export default function SearchableSelect<T extends string | number>({
  label,
  options,
  value,
  onChange,
  disabled,
  fullWidth = true,
  required,
  error,
  helperText,
  placeholder,
  size = "medium",
  disableClearable,
  loading,
  noOptionsText,
  onOpen,
  sx,
}: SearchableSelectProps<T>) {
  const selectedOption = options.find((option) => Object.is(option.value, value)) ?? null;

  return (
    <Autocomplete<SearchableOption<T>, false, boolean, false>
      options={options}
      value={selectedOption}
      onChange={(_, option) => onChange(option?.value ?? null)}
      getOptionLabel={(option) => option.label}
      isOptionEqualToValue={(option, nextValue) => Object.is(option.value, nextValue.value)}
      getOptionDisabled={(option) => Boolean(option.disabled)}
      filterOptions={filterOptions as AutocompleteProps<SearchableOption<T>, false, boolean, false>["filterOptions"]}
      autoHighlight
      openOnFocus
      onOpen={onOpen}
      disabled={disabled}
      fullWidth={fullWidth}
      disableClearable={disableClearable}
      loading={loading}
      noOptionsText={noOptionsText}
      sx={sx}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          placeholder={placeholder}
          required={required}
          error={error}
          helperText={helperText}
          size={size}
          InputProps={{
            ...params.InputProps,
            endAdornment: (
              <>
                {loading ? <CircularProgress color="inherit" size={18} /> : null}
                {params.InputProps.endAdornment}
              </>
            ),
          }}
        />
      )}
    />
  );
}
