{ pkgs, ... }: {
  systemd.services.alarm-to-mqtt = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "Connects MQTT server and AlarmDecoder";
    serviceConfig = {
      ExecStart =
        let
          alarm-to-mqtt = pkgs.writers.writePython3Bin "alarm-to-mqtt.py" { libraries = with pkgs.python3Packages; [ alarmdecoder paho-mqtt ]; } (
            builtins.readFile ./alarm-to-mqtt.py
          );
        in
        "${alarm-to-mqtt}/bin/alarm-to-mqtt.py";
    };
  };
}
