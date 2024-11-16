from pydantic_settings import BaseSettings


class ConfigSettings(BaseSettings):
    class Config:
        case_sensitive = True
        env_file = ".env"
        env_file_encoding = "utf-8"


class Config(ConfigSettings):
    MT5_USERNAME: str
    MT5_PASSWORD: str
    MT5_SERVER: str

config: Config = Config()