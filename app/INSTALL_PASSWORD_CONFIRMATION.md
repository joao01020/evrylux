# EVRYLUX — confirmação de senha para ações sensíveis

Este pacote atualiza os fluxos de Segurança para exigir a senha atual em três ações:

- Alterar senha;
- Excluir meus dados;
- Excluir conta.

## Fluxos

### Alterar senha

O diálogo solicita:

1. senha atual;
2. nova senha;
3. confirmação da nova senha.

A alteração usa `UserAttributes(currentPassword: ..., password: ...)`, permitindo que o Supabase valide a senha atual antes da troca.

### Excluir meus dados

O usuário continua digitando `EXCLUIR DADOS`. Depois disso, um segundo diálogo solicita a senha atual. A exclusão só começa após o Supabase Auth confirmar a senha.

### Excluir conta

O usuário continua digitando `EXCLUIR CONTA`. Depois disso, um segundo diálogo solicita a senha atual. A exclusão só começa após o Supabase Auth confirmar a senha.

A senha digitada no modal de confirmação não é persistida pelo EVRYLUX.

## Instalação

Na raiz do projeto:

```bash
cd /home/joao/Documentos/PlatformIO/Projects/ghost-core/app
unzip -o "/home/joao/Downloads/evrylux_security_password_confirmation_v1.zip" -d .
flutter pub get
flutter analyze
```
