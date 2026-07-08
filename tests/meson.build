test(
  'group-selection-batch',
  executable(
    'group-selection-batch',
    [
      files('group-selection-batch.vala'),
      meson.project_source_root() / 'src' / 'CleaningTarget.vala',
      meson.project_source_root() / 'src' / 'GroupSelectionBatch.vala',
    ],
    dependencies: [gee_dep],
  )
)

test(
  'scan-option-groups',
  executable(
    'scan-option-groups',
    [
      files('scan-option-groups.vala'),
      meson.project_source_root() / 'src' / 'Preferences.vala',
      meson.project_source_root() / 'src' / 'ScanOptionGroups.vala',
    ],
    dependencies: [dependency('gio-2.0')],
  )
)
