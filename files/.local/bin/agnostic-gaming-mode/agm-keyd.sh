#!/bin/bash

sudo systemctl enable --now keyd

sleep 2

sudo mv /etc/keyd/agnostic-gaming-mode.conf /etc/keyd/agnostic-gaming-mode.conf.disabled 2>/dev/null

sudo keyd reload
