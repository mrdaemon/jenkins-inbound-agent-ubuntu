# jenkins-inbound-agent-ubuntu

A ubuntu based Docker image suitable for use as a Jenkins Inbound Agent image, or a base image.
Mostly adapted off the official upstream Jenkins image, but rebased on Ubuntu, and streamlined somewhat.

## Should I use this?

Probably not, as I make no guarantees about updates or support.
This is mostly for my own usage, but it is made available for refrence and/or forking.

## Where do the scripts in files/ come from?

Blatantly stolen from the official usptream agent image. They are entirely unmodified, so all the
unquoted variables everywhere and questionable practices aren't mine to claim.

## Where is the upstream image?

The upstream image can be found in [this github repository](https://github.com/jenkinsci/docker-agent).

## So why did you make this again?

I exclusively use Docker workers in Jenkins, spawned on-demand off my internal cluster.
I have some cross-compilation targets and various things that loosely depend on Ubuntu over Debian.
I normally use the official debian based image and make my own workers from it.

## Are you _sure_ I can't use this?

If you've reviewed it and found nothing offensive, then sure, yes.
It functions exactly like the usptream inbound-agent image, and should be drop in.

## This Dockerfile is nasty

Yeah, I'm not fond of the structure either, and isn't representative of my normal style.
I mostly recycled the upstream work instead of rewriting all of it due to inertia and time
constraints. Sorry.
