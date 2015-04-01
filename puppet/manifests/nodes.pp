node default {
  crit( "Node only matched \"default\" for which there is no configuration, $::hostname" )
}

node wuk-dev {
  class {'beluga::mysql_server': }

  webnode { 'dev':
    prefix => 'dev.'
  }

  class { 'beluga::developer_tools':
    install_grunt             => false,
    install_git               => true,
  }

  class { 'jenkins':
    configure_firewall        => false,
  }

}

# Intranet LinuxDev01
node e03422 {
  webnode { 'dev':
    prefix => 'dev.'
  }
}

# Intranet LinuxStage01
node e03423 {
  webnode { 'stage1':
    prefix => 'stage1.'
  }
}

# Intranet LinuxStage02
node e03424 {
  webnode { 'stage2':
    prefix => 'stage2.'
  }
}

# Intranet LinuxIntranet01
node e02414 {
  webnode { 'live':
    prefix => ''
  }
}

# Intranet LinuxIntranet02
node e02415 {
  webnode { 'live':
    prefix => ''
  }
}

# Intranet DB Prod 01
node e02416 {

  include dbnode

}

# Intranet DB Prod 02
node e02417 {

  include dbnode

}

# Intranet DB Dev/Test 01
node e03425 {

  include dbnode

}

# Intranet DB Dev/Test 02
node e03426 {

  include dbnode

}

