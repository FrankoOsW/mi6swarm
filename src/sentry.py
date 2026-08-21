import os

from pydantic.tools import parse_obj_as


# If the sentry integration is enabled via setting the SENTRY_DSN
# environment varirable then we setup the integrations
def setup_sentry():
    SENTRY_DSN = parse_obj_as(str, os.getenv("SENTRY_DSN", ""))
    SENTRY_TRACES_SAMPLE_RATE = parse_obj_as(
        float, os.getenv("SENTRY_TRACES_SAMPLE_RATE", 0.01)
    )  # Float Range 0 - 1 - percentage of requests to trace - default to 1 %
    SENTRY_PROFILES_SAMPLES_RATE = parse_obj_as(
        float, os.getenv("SENTRY_PROFILES_SAMPLE_RATE", 0.01)
    )  # Float Range 0 - 1 - percentage of requests to profile - defaul to 1 %

    # setup sentry
    if SENTRY_DSN:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration

        # required by FastAPI
        from sentry_sdk.integrations.starlette import (
            StarletteIntegration,
        )

        sentry_sdk.init(
            dsn=SENTRY_DSN,
            traces_sample_rate=SENTRY_TRACES_SAMPLE_RATE,
            profiles_sample_rate=SENTRY_PROFILES_SAMPLES_RATE,
            integrations=[
                StarletteIntegration(
                    transaction_style="endpoint",
                    failed_request_status_codes=[403, range(500, 599)],
                ),
                FastApiIntegration(
                    transaction_style="endpoint",
                    failed_request_status_codes=[403, range(500, 599)],
                ),
            ],
        )
