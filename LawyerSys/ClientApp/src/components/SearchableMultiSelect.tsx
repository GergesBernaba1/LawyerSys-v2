"use client";

import React from "react";
import CheckBoxIcon from "@mui/icons-material/CheckBox";
import CheckBoxOutlineBlankIcon from "@mui/icons-material/CheckBoxOutlineBlank";
import {
  Autocomplete,
  Checkbox,
  CircularProgress,
  TextField,
  createFilterOptions,
  type AutocompleteProps,
  type SxProps,
  type Theme,
} from "@mui/material";
import type { SearchableOption } from "./SearchableSelect";

type SearchableMultiSelectProps<T extends string | number> = {
  label: string;
  options: SearchableOption<T>[];
  value: T[];
  onChange: (value: T[]) => void;
  disabled?: boolean;
  fullWidth?: boolean;
  required?: boolean;
  error?: boolean;
  helperText?: React.ReactNode;
  placeholder?: string;
  size?: "small" | "medium";
  limitTags?: number;
  loading?: boolean;
  noOptionsText?: React.ReactNode;
  onOpen?: () => void;
  sx?: SxProps<Theme>;
};

const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;
const filterOptions = createFilterOptions<SearchableOption>({
  stringify: (option) => [option.label, ...(option.keywords ?? [])].join(" "),
  trim: true,
});

export default function SearchableMultiSelect<T extends string | number>({
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
  limitTags = 2,
  loading,
  noOptionsText,
  onOpen,
  sx,
}: SearchableMultiSelectProps<T>) {
  const selectedOptions = options.filter((option) => value.some((selected) => Object.is(selected, option.value)));

  return (
    <Autocomplete<SearchableOption<T>, true, false, false>
      multiple
      disableCloseOnSelect
      options={options}
      value={selectedOptions}
      onChange={(_, selectedOptions) => onChange(selectedOptions.map((option) => option.value))}
      getOptionLabel={(option) => option.label}
      isOptionEqualToValue={(option, nextValue) => Object.is(option.value, nextValue.value)}
      getOptionDisabled={(option) => Boolean(option.disabled)}
      filterOptions={filterOptions as AutocompleteProps<SearchableOption<T>, true, false, false>["filterOptions"]}
      autoHighlight
      openOnFocus
      onOpen={onOpen}
      disabled={disabled}
      fullWidth={fullWidth}
      limitTags={limitTags}
      loading={loading}
      noOptionsText={noOptionsText}
      sx={sx}
      renderOption={(props, option, { selected }) => {
        const { key, ...optionProps } = props;

        return (
          <li key={key} {...optionProps}>
            <Checkbox
              icon={icon}
              checkedIcon={checkedIcon}
              checked={selected}
              sx={{ mr: 1 }}
            />
            {option.label}
          </li>
        );
      }}
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
