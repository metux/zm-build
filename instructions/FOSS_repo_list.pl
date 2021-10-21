@ENTRIES = (
   { name => "ant-1.7.0-ziputil-patched",            },
   { name => "ant-tar-patched",                      },
   { name => "ical4j-0.9.16-patched",                },
   { name => "junixsocket",                         tag    => "junixsocket-parent-2.0.4", remote => "gh-ks",},
   { name => "nekohtml-1.9.13",                      },
   { name => "java-html-sanitizer-release-20190610.1",remote => "zm-ow",},
   { name => "antisamy", remote => "zm-ow",          },
   { name => "zm-bulkprovision-admin-zimlet",        },
   { name => "zm-bulkprovision-store",               },
   { name => "zm-certificate-manager-admin-zimlet",  },
   { name => "zm-certificate-manager-store",         },
   { name => "zm-clientuploader-admin-zimlet",       },
   { name => "zm-clientuploader-store",              },
   { name => "zm-downloads",                         },
   { name => "zm-helptooltip-zimlet",                },
   { name => "zm-ldap-utilities",                    },
   { name => "zm-licenses",                          },
   { name => "zm-mailbox",                           },
   { name => "zm-migration-tools",                   },
   { name => "zm-nginx-lookup-store",                },
   { name => "zm-openid-consumer-store",             },
   { name => "zm-pkg-tool",                          },
   { name => "zm-proxy-config-admin-zimlet",         },
   { name => "zm-ssdb-ephemeral-store",              },
      # zm-timezones repo can be removed and made independent of zm-zextras
      # zm-timezones cannot be done unless the packages from it are pushed to public repo
      # zm-timezones is already excluded in CircleCI builds via --exclude-git-repo=...
   { name => "zm-timezones",                         },
   { name => "zm-versioncheck-admin-zimlet",         },
   { name => "zm-versioncheck-store",                },
   { name => "zm-versioncheck-utilities",            },
   { name => "zm-viewmail-admin-zimlet",             },
   { name => "zm-zcs",                               },
   { name => "zm-zcs-lib",                           },
   { name => "zm-zimlets",                           },
);
