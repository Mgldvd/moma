# Future enhancements

Label: [**enhancement**](https://github.com/Gogh-Co/Gogh/issues?q=is%3Aissue%20state%3Aopen%20label%3Aenhancement)

Status: Backlog only. These components are documented for future consideration and are not planned for implementation now.

## Priority proposals

### `moma-key-value`

Display aligned keys and values for configuration summaries and review screens.

```text
  Project       demo-project
  Environment   Development
  Features      Docker, Tests
  Owner         team@example.com
```

Suggested priority: High.

### `moma-progress`

Display determinate progress when a percentage is available. This component would complement `moma-spinner`.

```text
  ▪ Installing dependencies
  [████████████░░░░░░░░] 60%
```

Suggested priority: High.

### `moma-steps`

Display completed, active, and pending workflow stages.

```text
  ✔ Download
  ✔ Configure
  ▪ Install
  ○ Finish
```

Suggested priority: High.

## Additional proposals

### `moma-table`

Display structured results with multiple rows and columns.

```text
  NAME       STATUS    VERSION
  bash       ready     5.2
  curl       ready     8.5
```

Suggested priority: Medium.

### `moma-textarea`

Read multiline interactive input when `moma-input` is not sufficient.

Suggested priority: Medium.

### `moma-log`

Display timestamped messages with semantic levels.

```text
  14:32:08  INFO     Starting deployment
  14:32:11  SUCCESS  Deployment finished
```

Suggested priority: Low.

## Existing coverage

Do not create separate components for these behaviors:

- Password input is available through `moma-input --secret`.
- Checkbox selection is available through `moma-multi-select`.
- Radio-style selection is available through `moma-select`.
- Alerts are available through `moma-box` and `moma-msg`.

## Suggested implementation order

1. `moma-key-value`
2. `moma-progress`
3. `moma-steps`
4. `moma-table`
5. `moma-textarea`
6. `moma-log`
