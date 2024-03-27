# SNEWS_Operations
These are the useful bits for running the SNEWS 2.0 infrastructure.

## Apptainer usage:
Apptainer is a handy container environment that doesn't require administrative
access to install or execute.

### Data storage locations:
	~/apps
	~/data
	~/etc
	~/run

### Building the Apptainer container
	$ cd SNEWS_Operations/apps/snews_cs
	$ apptainer build snews_cs.img snews_cs.def

### Executing the Apptainer container
	$ apptainer run --app coinc snews_cs.img
	$ apptainer run --app feedback snews_cs.img

Note: 
It *is* possible to configure the container to 
not use localhost as the smtp relay, as well as use smtp-auth.
These items can be passed in through the environment
so that things like passwords are not laying in plain text.
They are also VERY environment specific and will differ
depending on where this container is launched from.

	apptainer run \
		--env smtp_server_addr=relay.physics.purdue.edu \
		--env snews_sender_email=snews@purdue.edu \
		--env snews_sender_pass=$(pass snews@purdue.edu) \
		--app coinc snews_cs.img firedrill

## Log rotations

It will eventually become necessary to rotate your log files.
An example configuration exists in [SNEWS_Operations/etc/logrotate/logrotate.conf](https://github.com/SNEWS2/SNEWS_Operations/blob/main/etc/logrotate/logrotate.conf).

An okay crontab might be configured like:

	7 1 * * * /usr/sbin/logrotate -l ~/data/logrotate/logrotate.log -s ~/run/logrotate/state ~/etc/logrotate/logrotate.conf

# Grafana graph configurations

These settings are used to generate the dashboard.  I believe this *should* be templated at some point, although it doesn't appear Grafana supports variables in the field name transformation, which could make things interesting.

	1. Click dashboard
	2. Add/Row
	3. Name: XENONnT at a glance
	4. Ok

## On/Off status panel
	1. Add/Visualization
	2. Transform data
	3. Add transformation
	4. Filter by name (unfortunately, this doesn't support the usage of variables yet)
	5. Field: Detector, Match: Is equal, Value: XENONnT

	6. Visualizaions: Stat
	7. itle: XENONnT
	8. Value mappings: Value: on -> green, off -> red
	9. Unit: Boolean - On/Off
	10. Calculation: Last, Fields: Status
	11. Apply/Save

## Heartbeats data
	1. Add/Visualization
	    1. Transform data
	    2. Add transformation
	    3. Filter by name (unfortunately, this doesn't support the usage of variables yet)
	    4. Field: Detector, Match: Is equal, Value: XENONnT

	2. Query:
	    1. Field: Recieved Times: Type Time
	    2. Field: Stamped Times: Type Time
	    3. Field: Status: Type String
	    4. Field: Time After Last: Type Number

	3. Visualizations: Table
	    1. Title: XENONnT Heartbeats
	    2. Decimals: 5

