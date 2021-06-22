#include <HTTPClient.h>
#include <ArduinoJson.h>

#include "secret.h"
#include "module.h"

class Discord: public Module {
    private:
        HTTPClient http;
        StaticJsonDocument<128> jsonDoc;

    public:
        String name = "Discord";
        moduleActions supportedActions = {
            .write = true,
            .draw = false,
            .browse = false,
            .settings = false
        };

        virtual void typing_start() override {
            http.begin("https://discord.com/api/channels/717879156246970382/typing");
            http.addHeader("Content-Type", "application/json");
            http.addHeader("Authorization", DISCORD_TOKEN);
            http.POST("{}");

            // String response = http.getString();
            // Serial.println(response);

            http.end();
        }

        virtual void send(char* text) override {
            http.begin("https://discord.com/api/channels/717879156246970382/messages");
            http.addHeader("Content-Type", "application/json");
            http.addHeader("Authorization", DISCORD_TOKEN);

            jsonDoc["content"] = text;

            String content;
            serializeJson(jsonDoc, content);

            http.POST(content);

            jsonDoc.clear();
            http.end();
        }

//STILL NEEDS IMPLEMENTATION
//switch left+right

//switch server

//send image

//settings: select servers to use (max 8)

//notifications
};