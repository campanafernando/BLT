# MVP — escopo funcional

## História

Como pessoa que organiza trabalho, quero registrar tarefas, atribuí-las a alguém e
acompanhar o que está atrasado, para não perder prazo e saber o que está com quem.

## Fluxo

1. Entrar com usuário e senha.
2. Ver minhas tarefas (criadas por mim ou atribuídas a mim), com filtro por status e vencimento.
3. Criar tarefa com título, descrição, vencimento e responsável.
4. Editar, concluir e reabrir.
5. Excluir tarefa que eu criei.

## Regras

- Tarefa só é visível para quem criou ou para quem foi atribuída.
- Apenas o criador exclui.
- Concluir é idempotente: concluir duas vezes não muda `completed_at`.
- Reabrir limpa `completed_at`.
- Atribuir exige usuário ativo.
- `is_overdue` é derivado: vencimento anterior a hoje e status diferente de concluída.
- Data de vencimento no passado é aceita (registro retroativo) e aparece como atrasada.

## Fora de escopo

- Comentários, anexos, etiquetas, subtarefas.
- Notificação em tempo real.
- Multiusuário por organização.
- Drag-and-drop.
