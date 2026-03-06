1..254 |ForEach-Object {Test-NetConnection  "192.168.0.$_"  } 
1..254 |ForEach-Object{(Resolve-DnsName  192.168.0.$_ ).NameHost}
