${ mkdir -p ${PORT_DEVICE}/apps}
${ mkdir -p ${PORT_DEVICE}/update/system}
define APK_template
SIGNAPKS += $(1)
$(1):
	@echo "resign apk: $1"
	@cp ${PORT_BUILD}/ColorSystem/app/$1 ${PORT_DEVICE}/apps
endef

define APK_ORIGIN_template
APKS_ORIGIN += $(1)
$(1):
	@echo "resign origin apk: $1"
	@cp ${PORT_DEVICE}/update/system/app/$1 ${PORT_DEVICE}/apps
endef

define APK_NOT_SIGN_template
APKS_NOT_SIGN += ${1}
${1}:
	@echo "not resign apk: $1"
	@cp ${PORT_BUILD}/ColorSystem/app/$1 ${PORT_DEVICE}/apps
endef

$(foreach apk, $(APPS_NEED_RESIGN) $(APPS_EXTRA) ${APPS_QCOM_ONLY}, \
	$(eval $(call APK_template,$(apk))))

$(foreach apk, $(APPS_KEEP_ORIGIN), \
	$(eval $(call APK_ORIGIN_template,$(apk))))	
	
$(foreach apk, $(APPS_NOT_RESIGN), \
	$(eval $(call APK_NOT_SIGN_template,$(apk))))	

sign : ${SIGNAPKS} ${APKS_ORIGIN}
	@echo "Sign all needed apks!"
	${PORT_TOOLS}/resign.sh dir ${PORT_DEVICE}/apps

.PHONY: update
update:
	@echo "Update new code"
	cat ${PORT_ROOT}/smali/sourcechange.txt ${PORT_ROOT}/last_smali/sourcechange.txt | sort | uniq > ${PORT_DEVICE}/sourcechange.txt
	${PORT_TOOLS}/patch_color_framework.sh ${PORT_ROOT}/last_smali/color ${PORT_ROOT}/smali/color ${PWD}/smali/ ${PORT_DEVICE}/sourcechange.txt

firstpatch : getsmali resource
	@echo "First patch, We will autopatch changed smali files, you should modify files in dir temp/reject"
    ifneq ($(ORGIN_SECOND_FRAMEWORK_NAME), )
		${PORT_TOOLS}/copy_fold.sh smali/${ORGIN_SECOND_FRAMEWORK_NAME}.out/ smali/framework.jar.out/
		rm -rf smali/${ORGIN_SECOND_FRAMEWORK_NAME}.out
    endif
	${PORT_TOOLS}/patch_color_framework.sh ${PORT_ROOT}/smali/android ${PORT_ROOT}/smali/color ${PWD}/smali/ ${PORT_ROOT}/smali/sourcechange.txt
	${ mkdir -p ${PORT_DEVICE}/custom-update}

basepackage :
	@echo "Compile base package from phone"
	@echo "But firstly you should be sure you can use adb in linux"
	${PORT_TOOLS}/releasetools/ota_target_from_phone -n

otapackage : OTA_ID := 

fullota : ${DST_JAR_OUT} sign ${APKS_NOT_SIGN}
	@echo "Build the full update package"
	rm -rf new-update/
	${PORT_TOOLS}/copy_fold.sh update/ new-update/
	echo "ro.build.author=${AUTHOR_NAME}" >> new-update/system/build.prop
	echo "ro.build.channel=${FROM_CHANNEL}" >> new-update/system/build.prop

	@echo "${PORT_BUILD}/ColorSystem/*"
	rm -rf new-update/system/media/audio new-update/system/media/video new-update/system/media/*.zip new-update/system/media/*.mp3 new-update/system/vendor/pcsuite.iso
	${PORT_TOOLS}/copy_fold.sh ${PORT_BUILD}/ColorSystem new-update/system
	rm -rf new-update/system/app/*
	${PORT_TOOLS}/resign.sh dir new-update/system/framework
	${PORT_TOOLS}/copy_fold.sh apps/ new-update/system/app
	${PORT_TOOLS}/copy_fold.sh out/framework new-update/system/framework
	${PORT_TOOLS}/copy_fold.sh out/framework-res.apk new-update/system/framework/
	${PORT_TOOLS}/copy_fold.sh out/oppo-framework-res.apk new-update/system/framework/

#we will use $(CUSTOM_UPDATE) to cover, so you need put your change file or some apk can't be deleted
	${PORT_TOOLS}/copy_fold.sh ${CUSTOM_UPDATE} new-update/

#	mv new-update/system/app/ColorOSforum.apk new-update/data/app
#	mv new-update/system/app/IFlySpeechService.apk new-update/data/app
#	mv new-update/system/app/OppoSpeechAssist.apk new-update/data/app
#	rm new-update/system/app/OppoLockScreenGlassBoard.apk

#	${PORT_TOOLS}/resign.sh dir new-update
#	${PORT_TOOLS}/oppo_sign.sh new-update
	rm -f color-update.zip
	cd new-update/; zip -q -r -y color-update.zip .; mv color-update.zip ..
	
	
