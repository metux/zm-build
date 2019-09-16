#!/bin/bash
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2009, 2010, 2011, 2013, 2014, 2015, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****

# Shell script to create zimbra core package


#-------------------- Configuration ---------------------------

currentScript="$(basename "$0" | cut -d "." -f 1)"               # zimbra-core
currentPackage="$(echo ${currentScript}build | cut -d "-" -f 2)" # corebuild

#-------------------- Util Functions ---------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

CreateDebianPackage()
{
   case "${arch}" in
      x86_64) debarch="amd64";;
      *) debarch="${arch}";;
   esac

   log 1 "Create debian package"

   mkdir -p "${repoDir}/zm-build/${currentPackage}/DEBIAN";

   cat ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post > ${repoDir}/zm-build/${currentPackage}/DEBIAN/postinst
   cat ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.pre  > ${repoDir}/zm-build/${currentPackage}/DEBIAN/preinst

   chmod 555 ${repoDir}/zm-build/${currentPackage}/DEBIAN/preinst
   chmod 555 ${repoDir}/zm-build/${currentPackage}/DEBIAN/postinst

   (
      set -e;
      cd ${repoDir}/zm-build/${currentPackage}
      find . -type f -print0 \
         | xargs -0 md5sum \
         | grep -v -w "DEBIAN/.*" \
         | sed -e "s@ [.][/]@ @" \
         | sort \
   ) > ${repoDir}/zm-build/${currentPackage}/DEBIAN/md5sums

   (
      set -e;
      MORE_DEPENDS=", zimbra-timezone-data (>= 1.0.1+1510156506-1.$PKG_OS_TAG) $(find ${repoDir}/zm-packages/ -name \*.deb \
                         | xargs -n1 basename \
                         | sed -e 's/_[0-9].*//' \
                         | grep -e zimbra-common- \
                         | sed '1s/^/, /; :a; {N;s/\n/, /;ba}')";

      cat ${repoDir}/zm-build/rpmconf/Spec/${currentScript}.deb \
         | sed -e "s/@@VERSION@@/${releaseNo}.${releaseCandidate}.${buildNo}.${os/_/.}/" \
               -e "s/@@branch@@/${buildTimeStamp}/" \
               -e "s/@@ARCH@@/${debarch}/" \
               -e "s/@@MORE_DEPENDS@@/${MORE_DEPENDS}/" \
               -e "/^%post$/ r ${currentScript}.post"
   ) > ${repoDir}/zm-build/${currentPackage}/DEBIAN/control

   (
      set -e;
      cd ${repoDir}/zm-build/${currentPackage}
      dpkg -b ${repoDir}/zm-build/${currentPackage} ${repoDir}/zm-build/${arch}
   )
}

CreateRhelPackage()
{
    MORE_DEPENDS=", zimbra-timezone-data >= 1.0.1+1510156506-1.$PKG_OS_TAG $(find ${repoDir}/zm-packages/ -name \*.rpm \
                       | xargs -n1 basename \
                       | sed -e 's/-[0-9].*//' \
                       | grep -e zimbra-common- \
                       | sed '1s/^/, /; :a; {N;s/\n/, /;ba}')";

    cat ${repoDir}/zm-build/rpmconf/Spec/${currentScript}.spec | \
    	sed -e "s/@@VERSION@@/${releaseNo}_${releaseCandidate}_${buildNo}.${os}/" \
            	-e "s/@@RELEASE@@/${buildTimeStamp}/" \
                -e "s/@@MORE_DEPENDS@@/${MORE_DEPENDS}/" \
            	-e "/^%pre$/ r ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.pre" \
            	-e "/Best email money can buy/ a Network edition" \
            	-e "/^%post$/ r ${repoDir}/zm-build/rpmconf/Spec/Scripts/${currentScript}.post" > ${repoDir}/zm-build/${currentScript}.spec
    (cd ${repoDir}/zm-build/corebuild; find opt -maxdepth 2 -type f -o -type l \
    	| sed -e 's|^|%attr(-, zimbra, zimbra) /|' >> \
    	${repoDir}/zm-build/${currentScript}.spec )
    echo "%attr(440, root, root) /etc/sudoers.d/01_zimbra" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(440, root, root) /etc/sudoers.d/02_zimbra-core" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, root, root) /opt/zimbra/bin" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/docs" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(444, zimbra, zimbra) /opt/zimbra/docs/*" >> \
    	${repoDir}/zm-build/${currentScript}.spec

    if [ "${buildType}" == "NETWORK" ]
    then
      echo "%attr(755, zimbra, zimbra) /opt/zimbra/docs/rebranding" >> \
         ${repoDir}/zm-build/${currentScript}.spec
      echo "%attr(444, zimbra, zimbra) /opt/zimbra/docs/rebranding/*" >> \
         ${repoDir}/zm-build/${currentScript}.spec
    fi

    echo "%attr(755, root, root) /opt/zimbra/contrib" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, root, root) /opt/zimbra/libexec" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/logger" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/conf" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(644, zimbra, zimbra) /opt/zimbra/conf/*" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/conf/externaldirsync" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(644, zimbra, zimbra) /opt/zimbra/conf/externaldirsync/*" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/conf/sasl2" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(644, zimbra, zimbra) /opt/zimbra/conf/sasl2/*" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/conf/zmconfigd" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(644, zimbra, zimbra) /opt/zimbra/conf/zmconfigd/*" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/db" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, root, root) /opt/zimbra/lib" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, zimbra, zimbra) /opt/zimbra/conf/crontabs" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, root, root) /opt/zimbra/common/lib/jylibs" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(-, root, root) /opt/zimbra/common/lib/perl5/Zimbra" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "%attr(755, zimbra, zimbra) /opt/zimbra/logger/db/work" >> \
    	${repoDir}/zm-build/${currentScript}.spec
    echo "" >> ${repoDir}/zm-build/${currentScript}.spec
    echo "%clean" >> ${repoDir}/zm-build/${currentScript}.spec
    (cd ${repoDir}/zm-build/${currentPackage}; \
    	rpmbuild --target ${arch} --define '_rpmdir ../' --buildroot=${repoDir}/zm-build/${currentPackage} -bb ${repoDir}/zm-build/${currentScript}.spec )
}

install_zm_core_utils() {
    install_conf_from zm-core-utils/conf \
        dhparam.pem.zcs zmlogrotate

    install_bin_from zm-core-utils/src/bin \
        antispam-mysql antispam-mysql.server antispam-mysqladmin \
        ldap.production mysql mysql.server mysqladmin postconf postfix \
        qshape zmaccts zmamavisdctl zmantispamctl zmantispamdbpasswd \
        zmantivirusctl zmapachectl zmarchivectl zmauditswatchctl zmblobchk \
        zmcaldebug zmcbpadmin zmcbpolicydctl zmcertmgr zmclamdctl \
        zmconfigdctl zmcontactbackup zmcontrol zmdedupe zmdhparam \
        zmdnscachectl zmdumpenv zmfixcalendtime zmfixcalprio zmfreshclamctl \
        zmgsautil zmhostname zminnotop zmitemdatafile zmjava zmjavaext \
        zmldappasswd zmldapupgrade zmlmtpinject zmlocalconfig zmloggerctl \
        zmloggerhostmap zmlogswatchctl zmmailbox zmmailboxdctl zmmemcachedctl \
        zmmetadump zmmigrateattrs zmmilterctl zmmtactl zmmypasswd \
        zmmysqlstatus zmmytop zmopendkimctl zmplayredo zmprov zmproxyconf \
        zmproxyctl zmpython zmredodump zmresolverctl zmsaslauthdctl zmshutil \
        zmskindeploy zmsoap zmspellctl zmsshkeygen zmstat-chart \
        zmstat-chart-config zmstatctl zmstorectl zmswatchctl zmthrdump \
        zmtlsctl zmtotp zmtrainsa zmtzupdate zmupdateauthkeys zmvolume \
        zmzimletctl

    install_file zm-core-utils/src/contrib/zmfetchercfg \
                 opt/zimbra/contrib/

    install_libexec_from zm-core-utils/src/libexec \
        600.zimbra client_usage_report.py configrewrite icalmig \
        libreoffice-installer.sh zcs zimbra zmaltermimeconfig \
        zmantispamdbinit zmantispammycnf zmcbpolicydinit \
        zmcheckduplicatemysqld zmcheckexpiredcerts  zmcleantmp \
        zmclientcertmgr zmcompresslogs zmcomputequotausage zmconfigd \
        zmcpustat zmdailyreport zmdbintegrityreport zmdiaglog \
        zmdkimkeyutil zmdnscachealign zmdomaincertmgr zmexplainslow \
        zmexplainsql zmextractsql zmfixperms zmfixreminder \
        zmgenentitlement zmgsaupdate zmhspreport zminiutil zmiostat \
        zmiptool zmjavawatch zmjsprecompile zmlogger zmloggerinit \
        zmlogprocess zmmsgtrace zmmtainit zmmtastatus zmmycnf \
        zmmyinit zmnotifyinstall zmpostfixpolicyd zmproxyconfgen \
        zmproxyconfig zmproxypurge zmqaction zmqstat zmqueuelog \
        zmrc zmrcd zmresetmysqlpassword zmrrdfetch zmsacompile \
        zmsaupdate zmserverips zmsetservername zmsnmpinit \
        zmspamextract zmstat-allprocs zmstat-cleanup zmstat-convertd \
        zmstat-cpu zmstat-df zmstat-fd zmstat-io zmstat-mtaqueue \
        zmstat-mysql zmstat-nginx zmstat-proc zmstat-vm zmstatuslog \
        zmsyslogsetup zmthreadcpu zmunbound zmupdatedownload zmupdatezco

    install_file zm-core-utils/src/perl/migrate20131014-removezca.pl \
                 opt/zimbra/libexec/scripts/
}

install_ne() {
    if [ "${buildType}" != "NETWORK" ]; then return 0 ; fi

    install_docs_from zm-backup-store/docs \
        backup.txt mailboxMove.txt soapbackup.txt xml-meta.txt

    install_file zm-backup-store/build/dist/backup-version-init.sql \
                 /opt/zimbra/db/

    install_bin_from zm-backup-utilities/src/bin \
        zmbackup zmbackupabort zmbackupquery zmmboxmove zmmboxmovequery \
        zmpurgeoldmbox zmrestore zmrestoreldap zmrestoreoffline \
        zmschedulebackup

    install_libexec_from zm-backup-utilities/src/libexec \
        zmbackupldap zmbackupqueryldap

    install_file zm-backup-utilities/src/db/backup_schema.sql \
                 opt/zimbra/db/

    install_conf zm-convertd-native/conf/convertd.log4j.properties

    install_bin zm-convertd-native/src/bin/zmconvertctl

    install_libexec zm-convertd-native/src/libexec/zmconvertdmod

    install_file zm-hsm/docs/soap-admin.txt \
                 opt/zimbra/docs/hsm-soap-admin.txt

    install_file zm-network-build/rpmconf/Install/Util/modules/postinstall.sh \
                 opt/zimbra/libexec/installer/util/modules/

    install_libexec \
        zm-network-build/rpmconf/Install/postinstall.pm \
        zm-network-build/rpmconf/Install/preinstall.pm

    install_docs \
        zm-network-licenses/thirdparty/keyview_eula.txt \
        zm-network-licenses/thirdparty/oracle_jdk_eula.txt

    install_libxec zm-postfixjournal/build/dist/postjournal

    for i in DE ES FR IT JA NL RU en_US pt_BR zh_CN zh_HK ; do
        install_file "zm-rebranding-docs/docs/rebranding/${i}_Rebranding_directions.txt" \
                     /opt/zimbra/docs/rebranding/
    done

    install_docs zm-twofactorauth-store/docs/twofactorauth.md

    install_libexec \
        zm-vmware-appmonitor/build/dist/libexec/vmware-appmonitor

    install_lib \
        zm-vmware-appmonitor/build/dist/lib/libappmonitorlib.so

    install_docs \
        zm-voice-store/docs/ZimbraVoice-Extension.txt \
        zm-voice-store/docs/soap-voice-admin.txt \
        zm-voice-store/docs/soap-voice.txt
}

install_zm_db_conf() {
    for i in Migrate.pm clearArchivedFlag.pl fixConversationCounts.pl \
             fixZeroChangeIdItems.pl \
             fixup20080410-SetRsvpTrue.pl \
             migrate-ComboUpdater.pl \
             migrate20050517-AddUnreadColumn.pl \
             migrate20050531-RemoveCascadingDeletes.pl \
             migrate20050609-AddDateIndex.pl \
             migrate20050628-ShrinkSyncColumns.pl \
             migrate20050701-SchemaCleanup.pl \
             migrate20050721-MailItemIndexes.pl \
             migrate20050727-RemoveTypeInvite.pl \
             migrate20050727a-Volume.pl \
             migrate20050804-SpamToJunk.pl \
             migrate20050809-AddConfig.pl \
             migrate20050811-WipeAppointments.pl \
             migrate20050818-TagsFlagsIndexes.pl \
             migrate20050822-TrackChangeDate.pl \
             migrate20050824-AddMailTransport.sh \
             migrate20050824a-Volume.pl \
             migrate20050831-SecondaryMsgVolume.pl \
             migrate20050916-Volume.pl \
             migrate20050920-CompressionThreshold.pl \
             migrate20050927-DropRedologSequence.pl \
             migrate20051021-UniqueVolume.pl \
             migrate20060120-Appointment.pl \
             migrate20060412-NotebookFolder.pl \
             migrate20060515-AddImapId.pl \
             migrate20060518-EmailedContactsFolder.pl \
             migrate20060708-FlagCalendarFolder.pl \
             migrate20060803-CreateMailboxMetadata.pl \
             migrate20060807-WikiDigestFixup.sh \
             migrate20060810-PersistFolderCounts.pl \
             migrate20060911-MailboxGroup.pl \
             migrate20060929-TypedTombstones.pl \
             migrate20061101-IMFolder.pl \
             migrate20061117-TasksFolder.pl \
             migrate20061120-AddNameColumn.pl \
             migrate20061204-CreatePop3MessageTable.pl \
             migrate20061205-UniqueAppointmentIndex.pl \
             migrate20061212-RepairMutableIndexIds.pl \
             migrate20061221-RecalculateFolderSizes.pl \
             migrate20070302-NullContactVolumeId.pl \
             migrate20070306-Pop3MessageUid.pl \
             migrate20070606-WidenMetadata.pl \
             migrate20070614-BriefcaseFolder.pl \
             migrate20070627-BackupTime.pl \
             migrate20070629-IMTables.pl \
             migrate20070630-LastSoapAccess.pl \
             migrate20070703-ScheduledTask.pl \
             migrate20070706-DeletedAccount.pl \
             migrate20070713-NullContactBlobDigest.pl \
             migrate20070725-CreateRevisionTable.pl \
             migrate20070726-ImapDataSource.pl \
             migrate20070809-Signatures.pl \
             migrate20070921-ImapDataSourceUidValidity.pl \
             migrate20070928-ScheduledTaskIndex.pl \
             migrate20071128-AccountId.pl \
             migrate20071202-DeleteSignatures.pl \
             migrate20071204-deleteOldLDAPUsers.pl \
             migrate20071206-WidenSizeColumns.pl \
             migrate20080130-ImapFlags.pl \
             migrate20080213-IndexDeferredColumn.pl \
             migrate20080909-DataSourceItemTable.pl \
             migrate20080930-MucService.pl \
             migrate20090315-MobileDevices.pl \
             migrate20090406-DataSourceItemTable.pl \
             migrate20090430-highestindexed.pl \
             migrate20100106-MobileDevices.pl \
             migrate20100913-Mysql51.pl \
             migrate20100926-Dumpster.pl \
             migrate20101123-MobileDevices.pl \
             migrate20110314-MobileDevices.pl \
             migrate20110330-RecipientsColumn.pl \
             migrate20110705-PendingAclPush.pl \
             migrate20110810-TagTable.pl \
             migrate20110928-MobileDevices.pl \
             migrate20110929-VersionColumn.pl \
             migrate20111005-ItemIdCheckpoint.pl \
             migrate20120125-uuidAndDigest.pl \
             migrate20120222-LastPurgeAtColumn.pl \
             migrate20120229-DropIMTables.pl \
             migrate20120319-Name255Chars.pl \
             migrate20120410-BlobLocator.pl \
             migrate20120611_7to8_bundle.pl \
             migrate20121009-VolumeBlobs.pl \
             migrate20130226_alwayson.pl \
             migrate20130227-UpgradeCBPolicyDSchema.sql \
             migrate20130606-UpdateCBPolicydSchema.sql \
             migrate20130819-UpgradeQuotasTable.sql \
             migrate20140319-MailItemPrevFolders.pl \
             migrate20140328-EnforceTableCharset.pl \
             migrate20140624-DropMysqlIndexes.pl \
             migrate20150401-ZmgDevices.pl \
             migrate20150515-DataSourcePurgeTables.pl \
             migrate20150623-ZmgDevices.pl \
             migrate20150702-ZmgDevices.pl \
             migrate20170301-ZimbraChat.pl \
             migrate20180301-ZimbraChat.pl \
             migrateAmavisLdap20050810.pl \
             migrateClearSpamFlag.pl \
             migrateLargeMetadata.pl \
             migrateLogger1-index.pl \
             migrateLogger2-config.pl \
             migrateLogger3-diskindex.pl \
             migrateLogger4-loghostname.pl \
             migrateLogger5-qid.pl \
             migrateLogger6-qid.pl \
             migrateMailItemTimestamps.pl \
             migratePreWidenSizeColumns.pl \
             migrateRemoveMailboxId.pl \
             migrateRemoveTagIndexes.pl \
             migrateRenameIdentifiers.pl \
             migrateSyncSequence.pl \
             migrateToSplitTables.pl \
             migrateUpdateAppointment.pl \
             optimizeMboxgroups.pl \
        ; do
            install_file "zm-db-conf/src/db/migration/$i" "opt/zimbra/libexec/scripts"
    done

    for i in create_database.sql db.sql ; do
        install_file "zm-db-conf/src/db/mysql/$i" opt/zimbra/db/
    done
}

install_zm_jython() {
    for i in commands.py conf.py config.py globalconfig.py ldap.py listener.py \
             localconfig.py logmsg.py miscconfig.py mtaconfig.py \
             serverconfig.py state.py \
        ; do
            install_file "zm-jython/jylibs/$i" "opt/zimbra/common/lib/jylibs/"
    done
}

#-------------------- main packaging ---------------------------

main()
{
   set -e

   Copy ${repoDir}/zm-build/rpmconf/Env/sudoers.d/01_zimbra                                         ${repoDir}/zm-build/${currentPackage}/etc/sudoers.d/01_zimbra
   Copy ${repoDir}/zm-build/rpmconf/Env/sudoers.d/02_zimbra-core                                    ${repoDir}/zm-build/${currentPackage}/etc/sudoers.d/02_zimbra-core

   Copy ${repoDir}/zm-amavis/conf/amavisd.conf.in                                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/amavisd.conf.in
   Copy ${repoDir}/zm-amavis/conf/amavisd/amavisd-custom.conf                                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/amavisd-custom.conf
   Copy ${repoDir}/zm-amavis/conf/dspam.conf.in                                                     ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/dspam.conf.in

   Copy ${repoDir}/zm-build/lib/Zimbra/DB/DB.pm                                                     ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/DB/DB.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/LDAP.pm                                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/LDAP.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/LocalConfig.pm                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/LocalConfig.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Mon/Logger.pm                                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Mon/Logger.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Mon/LoggerSchema.pm                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Mon/LoggerSchema.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Mon/Zmstat.pm                                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Mon/Zmstat.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SMTP.pm                                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SMTP.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SOAP/Soap.pm                                                 ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SOAP/Soap.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SOAP/Soap11.pm                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SOAP/Soap11.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SOAP/Soap12.pm                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SOAP/Soap12.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SOAP/XmlDoc.pm                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SOAP/XmlDoc.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/SOAP/XmlElement.pm                                           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/SOAP/XmlElement.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Util/Common.pm                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Util/Common.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Util/LDAP.pm                                                 ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Util/LDAP.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/Util/Timezone.pm                                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/Util/Timezone.pm
   Copy ${repoDir}/zm-build/lib/Zimbra/ZmClient.pm                                                  ${repoDir}/zm-build/${currentPackage}/opt/zimbra/common/lib/perl5/Zimbra/ZmClient.pm

   Copy ${repoDir}/zm-build/rpmconf/Build/get_plat_tag.sh                                           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/get_plat_tag.sh
   Copy ${repoDir}/zm-build/rpmconf/Build/get_plat_tag.sh                                           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/bin/get_plat_tag.sh
   Copy ${repoDir}/zm-build/rpmconf/Conf/auditswatchrc                                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/auditswatchrc.in
   Copy ${repoDir}/zm-build/rpmconf/Conf/logswatchrc                                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/logswatchrc
   Copy ${repoDir}/zm-build/rpmconf/Conf/swatchrc                                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/swatchrc.in
   Copy ${repoDir}/zm-build/rpmconf/Conf/zmssl.cnf.in                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmssl.cnf.in
   Copy ${repoDir}/zm-build/rpmconf/Env/crontabs/crontab                                            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/crontabs/crontab
   Copy ${repoDir}/zm-build/rpmconf/Env/crontabs/crontab.ldap                                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/crontabs/crontab.ldap
   Copy ${repoDir}/zm-build/rpmconf/Env/crontabs/crontab.logger                                     ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/crontabs/crontab.logger
   Copy ${repoDir}/zm-build/rpmconf/Env/crontabs/crontab.mta                                        ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/crontabs/crontab.mta
   Copy ${repoDir}/zm-build/rpmconf/Env/crontabs/crontab.store                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/crontabs/crontab.store
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.bash_profile                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.bash_profile
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.bashrc                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.bashrc
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.exrc                                                 ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.exrc
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.ldaprc                                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.ldaprc
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.platform                                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.platform
   Copy ${repoDir}/zm-build/rpmconf/Env/zimbra.viminfo                                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/.viminfo
   Copy ${repoDir}/zm-build/rpmconf/Img/connection_failed.gif                                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/logger/db/work/connection_failed.gif
   Copy ${repoDir}/zm-build/rpmconf/Img/data_not_available.gif                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/logger/db/work/data_not_available.gif
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/addUser.sh                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/addUser.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/addUser.sh                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/addUser.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/globals.sh                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/globals.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/modules/getconfig.sh                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/modules/getconfig.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/modules/packages.sh                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/modules/packages.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/modules/postinstall.sh                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/modules/postinstall.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/Util/utilfunc.sh                                        ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/util/utilfunc.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/install.sh                                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/installer/install.sh
   Copy ${repoDir}/zm-build/rpmconf/Install/postinstall.pm                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/postinstall.pm
   Copy ${repoDir}/zm-build/rpmconf/Install/preinstall.pm                                           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/preinstall.pm
   Copy ${repoDir}/zm-build/rpmconf/Install/zmsetup.pl                                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmsetup.pl
   Copy ${repoDir}/zm-build/rpmconf/Upgrade/zmupgrade.pm                                            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmupgrade.pm

    install_zm_core_utils
    install_zm_db_conf

   Copy ${repoDir}/zm-freshclam/freshclam.conf.in                                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/freshclam.conf.in

    install_zm_jython

   Copy ${repoDir}/zm-launcher/build/dist/zmmailboxdmgr                                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmmailboxdmgr
   Copy ${repoDir}/zm-launcher/build/dist/zmmailboxdmgr.unrestricted                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmmailboxdmgr.unrestricted 

   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/Exchange2000.xml                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/Exchange2000.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/Exchange2003.xml                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/Exchange2003.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/Exchange5.5.xml                           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/Exchange5.5.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/domino.xml                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/domino.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/novellGroupWise.xml                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/novellGroupWise.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/externaldirsync/openldap.xml                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/externaldirsync/openldap.xml
   Copy ${repoDir}/zm-ldap-utilities/conf/freshclam.conf.in                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/freshclam.conf.in
   Copy ${repoDir}/zm-ldap-utilities/conf/zmconfigd.cf                                              ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd.cf
   Copy ${repoDir}/zm-ldap-utilities/conf/zmconfigd.log4j.properties                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd.log4j.properties
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20110615-AddDynlist.pl               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20110615-AddDynlist.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20110721-AddUnique.pl                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20110721-AddUnique.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20111019-UniqueZimbraId.pl           ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20111019-UniqueZimbraId.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20120210-AddSearchNoOp.pl            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20120210-AddSearchNoOp.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20120507-UniqueDKIMSelector.pl       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20120507-UniqueDKIMSelector.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20140728-AddSSHA512.pl               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20140728-AddSSHA512.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20141022-AddTLSBits.pl               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20141022-AddTLSBits.pl
   Copy ${repoDir}/zm-ldap-utilities/src/ldap/migration/migrate20150930-AddSyncpovSessionlog.pl     ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/scripts/migrate20150930-AddSyncpovSessionlog.pl
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapanon                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapanon
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapapplyldif                                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapapplyldif
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapenable-mmr                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapenable-mmr
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapenablereplica                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapenablereplica
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapinit                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapinit
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapmmrtool                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapmmrtool
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapmonitordb                                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapmonitordb
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldappromote-replica-mmr                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldappromote-replica-mmr
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapreplicatool                                  ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapreplicatool
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapschema                                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapschema
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmldapupdateldif                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmldapupdateldif
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmreplchk                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmreplchk
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmslapadd                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmslapadd
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmslapcat                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmslapcat
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmslapd                                            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmslapd
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmslapindex                                        ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmslapindex
   Copy ${repoDir}/zm-ldap-utilities/src/libexec/zmstat-ldap                                        ${repoDir}/zm-build/${currentPackage}/opt/zimbra/libexec/zmstat-ldap

    install_file zm-licenses/zimbra/ypl-full.txt    opt/zimbra/docs/YPL.txt
    install_file zm-licenses/zimbra/zpl-full.txt    opt/zimbra/docs/ZPL.txt
    install_file zm-migration-tools/ReadMe.txt      opt/zimbra/docs/zmztozmig.txt

   Copy ${repoDir}/zm-mta/cbpolicyd.conf.in                                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/cbpolicyd.conf.in
   Copy ${repoDir}/zm-mta/clamd.conf.in                                                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/clamd.conf.in
   Copy ${repoDir}/zm-mta/opendkim-localnets.conf.in                                                ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/opendkim-localnets.conf.in
   Copy ${repoDir}/zm-mta/opendkim.conf.in                                                          ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/opendkim.conf.in
   Copy ${repoDir}/zm-mta/postfix_header_checks.in                                                  ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/postfix_header_checks.in
   Copy ${repoDir}/zm-mta/postfix_sasl_smtpd.conf                                                   ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/sasl2/smtpd.conf.in
   Copy ${repoDir}/zm-mta/salocal.cf.in                                                             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/salocal.cf.in
   Copy ${repoDir}/zm-mta/saslauthd.conf.in                                                         ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/saslauthd.conf.in
   Copy ${repoDir}/zm-mta/zmconfigd/postfix_content_filter.cf                                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/postfix_content_filter.cf
   Copy ${repoDir}/zm-mta/zmconfigd/smtpd_end_of_data_restrictions.cf                               ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/smtpd_end_of_data_restrictions.cf
   Copy ${repoDir}/zm-mta/zmconfigd/smtpd_recipient_restrictions.cf                                 ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/smtpd_recipient_restrictions.cf
   Copy ${repoDir}/zm-mta/zmconfigd/smtpd_relay_restrictions.cf                                     ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/smtpd_relay_restrictions.cf
   Copy ${repoDir}/zm-mta/zmconfigd/smtpd_sender_login_maps.cf                                      ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/smtpd_sender_login_maps.cf
   Copy ${repoDir}/zm-mta/zmconfigd/smtpd_sender_restrictions.cf                                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/conf/zmconfigd/smtpd_sender_restrictions.cf

   Cpy2 ${repoDir}/junixsocket/junixsocket-native/build/junixsocket-native-*.nar                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/
   Cpy2 ${repoDir}/junixsocket/junixsocket-native/build/libjunixsocket-native-*.so                  ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/

   Copy ${repoDir}/zm-bulkprovision-store/build/dist/commons-csv-1.2.jar                            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_bulkprovision/commons-csv-1.2.jar
   Copy ${repoDir}/zm-bulkprovision-store/build/dist/zm-bulkprovision-store*.jar                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_bulkprovision/com_zimbra_bulkprovision.jar

   Copy ${repoDir}/zm-certificate-manager-store/build/zm-certificate-manager-store*.jar             ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_cert_manager/com_zimbra_cert_manager.jar 

   Copy ${repoDir}/zm-clientuploader-store/build/zm-clientuploader-store*.jar                       ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_clientuploader/com_zimbra_clientuploader.jar

   # Copy SSDB Ephemeral storage extension + dependencies
   Cpy2 ${repoDir}/zm-ssdb-ephemeral-store/build/dist/zm-ssdb-ephemeral-store*.jar                  ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_ssdb_ephemeral_store/
   Cpy2 ${repoDir}/zm-zcs-lib/build/dist/jedis-2.9.0.jar                                            ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_ssdb_ephemeral_store/
   Cpy2 ${repoDir}/zm-zcs-lib/build/dist/commons-pool2-2.4.2.jar                                    ${repoDir}/zm-build/${currentPackage}/opt/zimbra/lib/ext/com_zimbra_ssdb_ephemeral_store/

    install_ne

   CreatePackage "${os}"
}

############################################################################
main "$@"
