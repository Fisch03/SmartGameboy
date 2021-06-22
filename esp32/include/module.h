struct moduleActions {
    bool write;
    bool draw;
    bool browse;
    bool settings;
};

class Module {
    public:
        String name = "unknown";
        moduleActions supportedActions = {false, false, false, false};

        virtual void typing_start() {};
        virtual void send(char* text) {};
};