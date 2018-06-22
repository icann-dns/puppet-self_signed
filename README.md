
# self_signed

#### Table of Contents

1. [Description](#description)

## Description

This module adds a `self_signed` resource type for creating self signed certificates

```puppet
  self_signed {$::fqdn:
    country      => uk,
    state        => 'North Yorks'
    locality     => 'york'
    organisation => 'ICANN',
    unit         => 'imrs',
  }
```

