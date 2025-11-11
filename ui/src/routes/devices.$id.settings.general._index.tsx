
import { useState , useEffect } from "react";

import { SettingsItem } from "@components/SettingsItem";
import { JsonRpcResponse, useJsonRpc } from "@/hooks/useJsonRpc";

import { SettingsPageHeader } from "../components/SettingsPageheader";
import { Button } from "../components/Button";
import notifications from "../notifications";
import Checkbox from "../components/Checkbox";
import InputField from "../components/InputField";
import { useDeviceUiNavigation } from "../hooks/useAppNavigation";
import { useDeviceStore } from "../hooks/stores";


export default function SettingsGeneralRoute() {
  const { send } = useJsonRpc();
  const { navigateTo } = useDeviceUiNavigation();
  const [autoUpdate, setAutoUpdate] = useState(true);
  const [updateMetadataURL, setUpdateMetadataURL] = useState("");
  const [tempUpdateMetadataURL, setTempUpdateMetadataURL] = useState("");

  const currentVersions = useDeviceStore(state => {
    const { appVersion, systemVersion } = state;
    if (!appVersion || !systemVersion) return null;
    return { appVersion, systemVersion };
  });

  useEffect(() => {
    send("getAutoUpdateState", {}, (resp: JsonRpcResponse) => {
      if ("error" in resp) return;
      setAutoUpdate(resp.result as boolean);
    });

    send("getUpdateMetadataURL", {}, (resp: JsonRpcResponse) => {
      if ("error" in resp) return;
      const url = resp.result as string;
      setUpdateMetadataURL(url);
      setTempUpdateMetadataURL(url);
    });
  }, [send]);

  const handleAutoUpdateChange = (enabled: boolean) => {
    send("setAutoUpdateState", { enabled }, (resp: JsonRpcResponse) => {
      if ("error" in resp) {
        notifications.error(
          `Failed to set auto-update: ${resp.error.data || "Unknown error"}`,
        );
        return;
      }
      setAutoUpdate(enabled);
    });
  };

  const handleUpdateMetadataURLSave = () => {
    send("setUpdateMetadataURL", { url: tempUpdateMetadataURL }, (resp: JsonRpcResponse) => {
      if ("error" in resp) {
        notifications.error(
          `Error saving update URL: ${resp.error.data || "Unknown error"}`,
        );
        return;
      }
      setUpdateMetadataURL(tempUpdateMetadataURL);
      notifications.success("Update URL saved successfully");
    });
  };

  return (
    <div className="space-y-4">
      <SettingsPageHeader
        title="General"
        description="Configure device settings and update preferences"
      />

      <div className="space-y-4">
        <div className="space-y-4 pb-2">
          <div className="mt-2 flex items-center justify-between gap-x-2">
            <SettingsItem
              title="Check for Updates"
              description={
                currentVersions ? (
                  <>
                    App: {currentVersions.appVersion}
                    <br />
                    System: {currentVersions.systemVersion}
                  </>
                ) : (
                  <>
                    App: Loading...
                    <br />
                    System: Loading...
                  </>
                )
              }
            />
            <div>
              <Button
                size="SM"
                theme="light"
                text="Check for Updates"
                onClick={() => navigateTo("./update")}
              />
            </div>
          </div>
          <div className="space-y-4">
            <SettingsItem
              title="Auto Update"
              description="Automatically update the device to the latest version"
            >
              <Checkbox
                checked={autoUpdate}
                onChange={e => {
                  handleAutoUpdateChange(e.target.checked);
                }}
              />
            </SettingsItem>
          </div>
          <div className="space-y-4">
            <SettingsItem
              title="Update Server URL"
              description="Custom URL for update metadata. Leave default to use official JetKVM updates."
            >
              <div className="flex gap-2 items-center">
                <InputField
                  size="SM"
                  type="text"
                  value={tempUpdateMetadataURL}
                  onChange={(e) => setTempUpdateMetadataURL(e.target.value)}
                  placeholder="https://api.jetkvm.com/releases"
                  className="flex-1"
                />
                <Button
                  size="SM"
                  theme="light"
                  text="Save"
                  onClick={handleUpdateMetadataURLSave}
                  disabled={tempUpdateMetadataURL === updateMetadataURL}
                />
              </div>
            </SettingsItem>
          </div>

          <div className="mt-2 flex items-center justify-between gap-x-2">
            <SettingsItem
              title="Reboot Device"
              description="Power cycle the JetKVM"
            />
            <div>
              <Button
                size="SM"
                theme="light"
                text="Reboot Device"
                onClick={() => navigateTo("./reboot")}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
