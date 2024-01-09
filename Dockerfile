# Copyright 2023 You-Sheng Yang and others
# SPDX-License-Identifier: Apache-2.0

FROM docker:latest

RUN apk add bash

COPY start.sh /start.sh
