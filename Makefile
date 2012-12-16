all:
	haxe \
	-D as3_native \
	-lib away3d \
	-lib starling \
	-lib feathers \
	-lib starling-particle-system \
	-swf-lib Starling.swf \
	-swf-lib Feathers.swf \
	-swf-lib Feathers-AzureMobileTheme.swf \
	-main Main \
	-swf test.swf \
	-swf-header 640:360:60:000000 \
	-resource pdesign.pex
	open test.swf
