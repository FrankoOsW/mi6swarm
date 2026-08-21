from pydantic import BaseModel, SecretStr


class Message(BaseModel):
    message: str


class User(BaseModel):
    name: str
    password: SecretStr
