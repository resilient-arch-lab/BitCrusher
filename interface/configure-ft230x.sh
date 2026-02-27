#!/bin/bash
cd ftx-prog &&
make &&
yes "y" | ./ftx_prog --cbus 0 GPIO &&
yes "y" | ./ftx_prog --cbus 1 GPIO