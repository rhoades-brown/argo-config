while ($true) {
   start-sleep -Seconds 0.5
   Invoke-restmethod -Uri "https://whoami.services.rhoades-brown.local/api" -SkipCertificateCheck | Select name, hostname 
  }
