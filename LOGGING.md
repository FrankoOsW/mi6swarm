# logger setup

There are two ENV Variables that are used for the logging:

```console
LOG_LEVEL="DEBUG"
LOG_JSON_FORMAT=true

JSON LogFormatting is aimed at the container runtime environment and filters certain endpoints from being logged.

## disabling endpoint path logging

The `src/custom_logging.py` file contains a list, `DROP_ENDPOINTS`, that defines which routes are dropped from the JSON logs.

## changing the kubernetes output

The current uvicorn start and stop logs are silenced and are not outputted to the kubernetes pod logs. In order to enable the messages, make the following changes to `uvicorn_disable_logging.json`.

```diff
diff --git a/uvicorn_disable_logging.json b/uvicorn_disable_logging.json
index e0e1ba0..ebe26ff 100644
--- a/uvicorn_disable_logging.json
+++ b/uvicorn_disable_logging.json
@@ -27,14 +27,14 @@
             "handlers": [
                 "default"
             ],
-            "propagate": false
+            "propagate": true
         },
         "uvicorn.access": {
             "level": "INFO",
             "handlers": [
                 "access"
             ],
-            "propagate": false
+            "propagate": true
         }
     }
 }
```

The above change will show the following output

```console
pipenv run uvicorn src.main:app --reload --log-config=uvicorn_disable_logging.json
{"message": "Started server process [21373]"}
{"message": "Waiting for application startup."}
{"message": "Application startup complete."}
^C{"message": "Shutting down"}
{"message": "Waiting for application shutdown."}
{"message": "Application shutdown complete."}
{"message": "Finished server process [21373]"}
```

