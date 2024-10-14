# CFLintBox

CF Auto Linter Box Runner

`{cflintbox}`

### Usage

```
box install
```

- Install the box
- Update the config.json file with the directory you want to scan
- Run box server start
- Comes with CFLint 1.5, but use what ever version you want. Just update the path to the linter in the application.
- Flags:
  - ?reload=true: Restart the application / scan process. Aborts after the app start. Go back to /index.cfm to view results
  - ?dumpResults=true: Dump the results to the screen. Aborts after the dump. Go back to /index.cfm to view results
