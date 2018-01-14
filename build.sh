#!/bin/bash

hugo && rsync -rv public/ root@www.mikenewswanger.com:/var/www/www.mikenewswanger.com/html

