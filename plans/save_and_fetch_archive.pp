# This plan leverages two other tasks, to trigger an immediate archive of the
# current configuration, then transfer the archive to the local system, and
# finally delete the archive from the remote system.
#
# It needs several parameters passed in, to function.
#
# nodes:
#   Provided by bolt's --nodes flag.
#
# devices:
#   The target devices to fetch archives from
#
# device_port:
#   The port to make API calls over.  Defaults to 443.
#
# api_user:
#   The user to authenticate to the API as
#
# api_password:
#   The password to use for API authentication
#
# scp_user:
#   The user to `scp` as.  This user must have a local id_rsa private key, and
#     a remote public key in the target user's authorized_keys file.
#
# scp_identity_file:
#   The path to the id_rsa file on the local system that matches the public key
#     on the f5 device.
#
# local_backup_dir:
#   The path to backup directories.  This plan will create a device-specific
#     subdirectory in this directory, and transfer archive files into it.
#
# tidy_backup_dir:
#   Whether or not to remove two-week-old backups from the local_backup_dir.
#     Defaults to true.

plan f5_tasks::save_and_fetch_archive (
  TargetSpec $nodes,
  TargetSpec $devices,
  String $device_port       = '443',
  String $api_user,
  String $api_password,
  String $scp_user          = 'admin',
  String $scp_identity_file = '~/.ssh/id_rsa',
  String $local_backup_dir  = '/tmp/f5',
  Boolean $tidy_backup_dir  = true,
) {

  # Get an array of all the target device names
  $device_array = get_targets($devices).map |$w| { $w.name }

  # For each device, trigger an archive, fetch it, and delete it.
  $device_array.each |$device_name| {

    # Run the task to save the archive.  By default this file will end up in
    # /var/local/ucs/backup-<date>.ucs.
    run_task('f5_tasks::ucs_save',
      $nodes,
      device_name  => $device_name,
      device_port  => $device_port,
      api_user     => $api_user,
      api_password => $api_password,
    )

    # Get the zonefile-style year month and date now
    $yyyymmdd = strftime(Timestamp(),'%Y%m%d')

    # Use `scp` to fetch the backup file from its default location today
    run_command("if [ ! -d ${local_backup_dir}/${device_name} ]; then mkdir -p ${local_backup_dir}/${device_name} ; fi",$nodes)
    run_command("scp -i ${scp_identity_file} ${scp_user}@${device_name}:/var/local/ucs/backup-${yyyymmdd}.ucs ${local_backup_dir}/${device_name}",$nodes)

    # If desired, tidy up the backup directory
    if $tidy_backup_dir {
      run_command("find ${local_backup_dir}/${device_name} -type f -mtime +14 -delete",$nodes)
    }

    # Trigger deletion of the backup on the remote system
    run_task('f5_tasks::ucs_delete',
      $nodes,
      device_name  => $device_name,
      device_port  => $device_port,
      api_user     => $api_user,
      api_password => $api_password,
      file_name    => "backup-${yyyymmdd}.ucs",
    )

  }


}
