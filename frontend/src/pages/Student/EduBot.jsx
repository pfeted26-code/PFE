import { useEffect, useMemo, useRef, useState } from "react";
import {
  ArrowUp,
  Bot,
  Check,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Edit2,
  FileText,
  Menu,
  MessageSquare,
  MoreHorizontal,
  Paperclip,
  Plus,
  Search,
  Sparkles,
  Trash2,
  Upload,
  User,
  X,
} from "lucide-react";

import {
  sendChatMessage,
  uploadFile,
} from "../../services/chatService";

const QUICK_PROMPTS = [
  {
    icon: "📚",
    title: "My courses",
    prompt: "Show me my courses and summarize what I should study today.",
  },
  {
    icon: "📝",
    title: "My exams",
    prompt: "Show me my upcoming exams and recent grades.",
  },
  {
    icon: "📅",
    title: "My schedule",
    prompt: "What classes do I have today?",
  },
  {
    icon: "✅",
    title: "My attendance",
    prompt: "Show me my attendance status and absences.",
  },
];

const createMessageId = () => {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
};

const getCurrentTime = () =>
  new Date().toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });

const ensureStorage = () => {
  if (typeof window === "undefined") {
    return;
  }

  if (!window.storage) {
    window.storage = {
      get: async (key) => {
        try {
          const value = localStorage.getItem(key);
          return value ? { value } : null;
        } catch {
          return null;
        }
      },

      set: async (key, value) => {
        try {
          localStorage.setItem(key, value);
        } catch {
          // Local storage can be unavailable in private mode.
        }
      },

      list: async (prefix) => {
        try {
          const keys = Object.keys(localStorage).filter((key) =>
            key.startsWith(prefix)
          );

          return { keys };
        } catch {
          return { keys: [] };
        }
      },

      delete: async (key) => {
        try {
          localStorage.removeItem(key);
        } catch {
          // Ignore local storage deletion errors.
        }
      },
    };
  }
};

ensureStorage();

export default function ChatPage() {
  const [conversations, setConversations] = useState([]);
  const [currentConversationId, setCurrentConversationId] =
    useState(null);
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [userId, setUserId] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [mobileSidebarOpen, setMobileSidebarOpen] =
    useState(false);
  const [editingConvId, setEditingConvId] = useState(null);
  const [editingTitle, setEditingTitle] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFile, setSelectedFile] = useState(null);
  const [showDeleteModal, setShowDeleteModal] =
    useState(false);
  const [conversationToDelete, setConversationToDelete] =
    useState(null);

  const messagesEndRef = useRef(null);
  const textareaRef = useRef(null);
  const fileInputRef = useRef(null);

  useEffect(() => {
    const initialize = async () => {
      const resolvedUserId = "default-user";
      setUserId(resolvedUserId);

      try {
        const sidebarResult = await window.storage.get(
          "sidebarOpen"
        );

        if (sidebarResult) {
          setSidebarOpen(sidebarResult.value === "true");
        }
      } catch {
        setSidebarOpen(true);
      }

      await loadConversations(resolvedUserId);
    };

    initialize();
  }, []);

  useEffect(() => {
    if (userId) {
      window.storage.set(
        "sidebarOpen",
        String(sidebarOpen)
      );
    }
  }, [sidebarOpen, userId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({
      behavior: "smooth",
    });
  }, [messages, isLoading]);

  useEffect(() => {
    if (!textareaRef.current) {
      return;
    }

    textareaRef.current.style.height = "auto";
    textareaRef.current.style.height = `${Math.min(
      textareaRef.current.scrollHeight,
      160
    )}px`;
  }, [inputMessage]);

  const currentConversation = useMemo(
    () =>
      conversations.find(
        (conversation) =>
          conversation.id === currentConversationId
      ),
    [conversations, currentConversationId]
  );

  const filteredConversations = useMemo(() => {
    const normalizedSearch = searchQuery
      .trim()
      .toLowerCase();

    if (!normalizedSearch) {
      return conversations;
    }

    return conversations.filter((conversation) =>
      String(conversation.title || "")
        .toLowerCase()
        .includes(normalizedSearch)
    );
  }, [conversations, searchQuery]);

  const totalMessages = messages.length;

  const loadConversations = async (uid) => {
    try {
      const result = await window.storage.list(
        `conv_${uid}_`
      );

      const keys = Array.isArray(result?.keys)
        ? result.keys
        : [];

      const loadedConversations = (
        await Promise.all(
          keys.map(async (key) => {
            try {
              const stored = await window.storage.get(key);

              return stored?.value
                ? JSON.parse(stored.value)
                : null;
            } catch {
              return null;
            }
          })
        )
      )
        .filter(Boolean)
        .sort(
          (first, second) =>
            new Date(second.updatedAt) -
            new Date(first.updatedAt)
        );

      setConversations(loadedConversations);

      if (loadedConversations.length === 0) {
        await createNewConversation(uid);
        return;
      }

      setCurrentConversationId(
        loadedConversations[0].id
      );
      setMessages(
        loadedConversations[0].messages || []
      );
    } catch {
      await createNewConversation(uid);
    }
  };

  const createNewConversation = async (
    uid = userId
  ) => {
    if (!uid) {
      return;
    }

    const now = new Date().toISOString();

    const newConversation = {
      id: `conv_${Date.now()}`,
      title: "New conversation",
      messages: [],
      createdAt: now,
      updatedAt: now,
    };

    await window.storage.set(
      `conv_${uid}_${newConversation.id}`,
      JSON.stringify(newConversation)
    );

    setConversations((current) => [
      newConversation,
      ...current,
    ]);
    setCurrentConversationId(newConversation.id);
    setMessages([]);
    setMobileSidebarOpen(false);

    requestAnimationFrame(() => {
      textareaRef.current?.focus();
    });
  };

  const saveConversation = async (
    conversationId,
    nextMessages
  ) => {
    const conversation = conversations.find(
      (item) => item.id === conversationId
    );

    if (!conversation || !userId) {
      return;
    }

    const firstUserMessage = nextMessages.find(
      (message) => message.sender === "user"
    );

    const generatedTitle =
      firstUserMessage?.text
        ?.replace(/\s+/g, " ")
        .trim()
        .slice(0, 42) || "New conversation";

    const updatedConversation = {
      ...conversation,
      messages: nextMessages,
      updatedAt: new Date().toISOString(),
      title:
        conversation.title === "New conversation" ||
        conversation.title === "New Chat"
          ? generatedTitle
          : conversation.title,
    };

    await window.storage.set(
      `conv_${userId}_${conversationId}`,
      JSON.stringify(updatedConversation)
    );

    setConversations((current) =>
      current
        .map((item) =>
          item.id === conversationId
            ? updatedConversation
            : item
        )
        .sort(
          (first, second) =>
            new Date(second.updatedAt) -
            new Date(first.updatedAt)
        )
    );
  };

  const switchConversation = (conversationId) => {
    const conversation = conversations.find(
      (item) => item.id === conversationId
    );

    if (!conversation) {
      return;
    }

    setCurrentConversationId(conversationId);
    setMessages(conversation.messages || []);
    setMobileSidebarOpen(false);

    requestAnimationFrame(() => {
      textareaRef.current?.focus();
    });
  };

  const renameConversation = async (
    conversationId,
    title
  ) => {
    const cleanTitle = String(title || "").trim();

    if (!cleanTitle || !userId) {
      return;
    }

    const conversation = conversations.find(
      (item) => item.id === conversationId
    );

    if (!conversation) {
      return;
    }

    const updatedConversation = {
      ...conversation,
      title: cleanTitle,
    };

    await window.storage.set(
      `conv_${userId}_${conversationId}`,
      JSON.stringify(updatedConversation)
    );

    setConversations((current) =>
      current.map((item) =>
        item.id === conversationId
          ? updatedConversation
          : item
      )
    );

    setEditingConvId(null);
    setEditingTitle("");
  };

  const deleteConversation = async (
    conversationId
  ) => {
    if (!userId) {
      return;
    }

    await window.storage.delete(
      `conv_${userId}_${conversationId}`
    );

    const remainingConversations =
      conversations.filter(
        (item) => item.id !== conversationId
      );

    setConversations(remainingConversations);

    if (currentConversationId !== conversationId) {
      return;
    }

    if (remainingConversations.length > 0) {
      setCurrentConversationId(
        remainingConversations[0].id
      );
      setMessages(
        remainingConversations[0].messages || []
      );
      return;
    }

    await createNewConversation(userId);
  };

  const extractAssistantText = (response) => {
    if (typeof response === "string") {
      return response.trim();
    }

    const answer =
      response?.answer ||
      response?.reply ||
      response?.response ||
      response?.message ||
      response?.content;

    return typeof answer === "string"
      ? answer.trim()
      : "";
  };

  const sendMessage = async (
    messageOverride = null
  ) => {
    const cleanMessage = String(
      messageOverride ?? inputMessage
    ).trim();

    if (
      !cleanMessage ||
      !currentConversationId ||
      !userId ||
      isLoading
    ) {
      return;
    }

    const userMessage = {
      id: createMessageId(),
      sender: "user",
      text: cleanMessage,
      timestamp: getCurrentTime(),
    };

    const nextMessages = [...messages, userMessage];

    setMessages(nextMessages);
    setInputMessage("");
    setIsLoading(true);

    try {
      const response = await sendChatMessage(
        cleanMessage,
        userId,
        currentConversationId
      );

      const answer = extractAssistantText(response);

      if (!answer) {
        throw new Error(
          "The server returned an empty AI response."
        );
      }

      const assistantMessage = {
        id: createMessageId(),
        sender: "ai",
        text: answer,
        timestamp: getCurrentTime(),
      };

      const finalMessages = [
        ...nextMessages,
        assistantMessage,
      ];

      setMessages(finalMessages);
      await saveConversation(
        currentConversationId,
        finalMessages
      );
    } catch (error) {
      console.error("Chat error:", error);

      const errorMessage = {
        id: createMessageId(),
        sender: "ai",
        text:
          error?.message ||
          "Sorry, I am having trouble connecting right now.",
        timestamp: getCurrentTime(),
        isError: true,
      };

      const finalMessages = [
        ...nextMessages,
        errorMessage,
      ];

      setMessages(finalMessages);
      await saveConversation(
        currentConversationId,
        finalMessages
      );
    } finally {
      setIsLoading(false);

      requestAnimationFrame(() => {
        textareaRef.current?.focus();
      });
    }
  };

  const handleKeyDown = (event) => {
    if (
      event.key === "Enter" &&
      !event.shiftKey
    ) {
      event.preventDefault();
      sendMessage();
    }
  };

  const handleFileSelect = async (event) => {
    const file = event.target.files?.[0];

    if (!file || !currentConversationId) {
      return;
    }

    setSelectedFile(file);
    setIsLoading(true);

    const userMessage = {
      id: createMessageId(),
      sender: "user",
      text: `Uploaded file: ${file.name}`,
      timestamp: getCurrentTime(),
      fileName: file.name,
    };

    const nextMessages = [...messages, userMessage];
    setMessages(nextMessages);

    try {
      const response = await uploadFile(file);
      const analysis = extractAssistantText(response);

      const assistantMessage = {
        id: createMessageId(),
        sender: "ai",
        text:
          analysis ||
          "The file was uploaded successfully.",
        timestamp: getCurrentTime(),
      };

      const finalMessages = [
        ...nextMessages,
        assistantMessage,
      ];

      setMessages(finalMessages);
      await saveConversation(
        currentConversationId,
        finalMessages
      );
    } catch (error) {
      console.error("File upload error:", error);

      const errorMessage = {
        id: createMessageId(),
        sender: "ai",
        text:
          error?.message ||
          "I could not process this file.",
        timestamp: getCurrentTime(),
        isError: true,
      };

      const finalMessages = [
        ...nextMessages,
        errorMessage,
      ];

      setMessages(finalMessages);
      await saveConversation(
        currentConversationId,
        finalMessages
      );
    } finally {
      setIsLoading(false);
      setSelectedFile(null);

      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  return (
    <main className="relative flex h-full min-h-[calc(100vh-72px)] overflow-hidden bg-slate-50 dark:bg-slate-950">
      {/* Mobile sidebar backdrop */}
      {mobileSidebarOpen && (
        <button
          type="button"
          aria-label="Close conversations"
          onClick={() =>
            setMobileSidebarOpen(false)
          }
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm lg:hidden"
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-[310px] flex-col border-r border-slate-200/80 bg-white/95 shadow-2xl backdrop-blur-xl transition-transform duration-300 dark:border-slate-800 dark:bg-slate-900/95 lg:static lg:z-auto lg:shadow-none ${
          mobileSidebarOpen
            ? "translate-x-0"
            : "-translate-x-full"
        } ${
          sidebarOpen
            ? "lg:w-[310px] lg:translate-x-0"
            : "lg:w-0 lg:-translate-x-full lg:overflow-hidden"
        }`}
      >
        <div className="border-b border-slate-200/80 p-4 dark:border-slate-800">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-lg shadow-blue-500/20">
                <Sparkles className="h-5 w-5 text-white" />
              </div>

              <div>
                <h2 className="font-black text-slate-900 dark:text-white">
                  AI Assistant
                </h2>

                <p className="text-xs text-slate-500 dark:text-slate-400">
                  Your academic companion
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={() => {
                setSidebarOpen(false);
                setMobileSidebarOpen(false);
              }}
              className="flex h-9 w-9 items-center justify-center rounded-xl text-slate-500 transition hover:bg-slate-100 hover:text-slate-900 dark:hover:bg-slate-800 dark:hover:text-white"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
          </div>

          <button
            type="button"
            onClick={() =>
              createNewConversation()
            }
            className="mt-5 flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-blue-600 to-violet-600 text-sm font-bold text-white shadow-lg shadow-blue-500/20 transition hover:-translate-y-0.5 hover:shadow-xl"
          >
            <Plus className="h-5 w-5" />
            New conversation
          </button>

          <div className="relative mt-4">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />

            <input
              type="text"
              value={searchQuery}
              onChange={(event) =>
                setSearchQuery(event.target.value)
              }
              placeholder="Search conversations"
              className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 dark:border-slate-700 dark:bg-slate-800 dark:text-white"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-3">
          <p className="px-2 pb-2 text-[11px] font-bold uppercase tracking-[0.16em] text-slate-400">
            Recent conversations
          </p>

          {filteredConversations.length === 0 ? (
            <div className="flex min-h-56 flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300 p-6 text-center dark:border-slate-700">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 dark:bg-slate-800">
                <MessageSquare className="h-6 w-6 text-slate-400" />
              </div>

              <p className="mt-4 text-sm font-bold text-slate-700 dark:text-slate-200">
                No conversations found
              </p>

              <p className="mt-1 text-xs leading-5 text-slate-500">
                Start a new discussion with your assistant.
              </p>
            </div>
          ) : (
            <div className="space-y-1.5">
              {filteredConversations.map(
                (conversation) => {
                  const isActive =
                    conversation.id ===
                    currentConversationId;

                  return (
                    <div
                      key={conversation.id}
                      role="button"
                      tabIndex={0}
                      onClick={() =>
                        switchConversation(
                          conversation.id
                        )
                      }
                      onKeyDown={(event) => {
                        if (
                          event.key === "Enter" ||
                          event.key === " "
                        ) {
                          switchConversation(
                            conversation.id
                          );
                        }
                      }}
                      className={`group rounded-2xl border p-3.5 transition ${
                        isActive
                          ? "border-blue-500/30 bg-blue-500/10 shadow-sm"
                          : "border-transparent hover:border-slate-200 hover:bg-slate-50 dark:hover:border-slate-700 dark:hover:bg-slate-800/70"
                      }`}
                    >
                      {editingConvId ===
                      conversation.id ? (
                        <div
                          className="flex items-center gap-2"
                          onClick={(event) =>
                            event.stopPropagation()
                          }
                        >
                          <input
                            type="text"
                            value={editingTitle}
                            onChange={(event) =>
                              setEditingTitle(
                                event.target.value
                              )
                            }
                            onKeyDown={(event) => {
                              if (
                                event.key === "Enter"
                              ) {
                                renameConversation(
                                  conversation.id,
                                  editingTitle
                                );
                              }

                              if (
                                event.key === "Escape"
                              ) {
                                setEditingConvId(
                                  null
                                );
                              }
                            }}
                            autoFocus
                            className="h-9 min-w-0 flex-1 rounded-lg border border-blue-500 bg-white px-3 text-sm outline-none dark:bg-slate-900"
                          />

                          <button
                            type="button"
                            onClick={() =>
                              renameConversation(
                                conversation.id,
                                editingTitle
                              )
                            }
                            className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600 text-white"
                          >
                            <Check className="h-4 w-4" />
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-start gap-3">
                          <div
                            className={`mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
                              isActive
                                ? "bg-blue-600 text-white"
                                : "bg-slate-100 text-slate-500 dark:bg-slate-800"
                            }`}
                          >
                            <MessageSquare className="h-4 w-4" />
                          </div>

                          <div className="min-w-0 flex-1">
                            <p className="truncate text-sm font-bold text-slate-800 dark:text-slate-100">
                              {conversation.title}
                            </p>

                            <div className="mt-1.5 flex items-center gap-2 text-[11px] text-slate-400">
                              <span>
                                {conversation.messages
                                  ?.length || 0}{" "}
                                messages
                              </span>

                              <span>•</span>

                              <span>
                                {formatConversationDate(
                                  conversation.updatedAt
                                )}
                              </span>
                            </div>
                          </div>

                          <div className="flex shrink-0 gap-1 opacity-0 transition group-hover:opacity-100">
                            <button
                              type="button"
                              onClick={(event) => {
                                event.stopPropagation();
                                setEditingConvId(
                                  conversation.id
                                );
                                setEditingTitle(
                                  conversation.title
                                );
                              }}
                              className="flex h-8 w-8 items-center justify-center rounded-lg text-slate-400 transition hover:bg-white hover:text-blue-600 dark:hover:bg-slate-900"
                            >
                              <Edit2 className="h-3.5 w-3.5" />
                            </button>

                            <button
                              type="button"
                              onClick={(event) => {
                                event.stopPropagation();
                                setConversationToDelete(
                                  conversation
                                );
                                setShowDeleteModal(
                                  true
                                );
                              }}
                              className="flex h-8 w-8 items-center justify-center rounded-lg text-slate-400 transition hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                }
              )}
            </div>
          )}
        </div>

        <div className="border-t border-slate-200/80 p-4 dark:border-slate-800">
          <div className="flex items-center justify-between rounded-2xl bg-slate-50 px-4 py-3 dark:bg-slate-800/70">
            <div>
              <p className="text-xs font-bold text-slate-700 dark:text-slate-200">
                Chat history
              </p>

              <p className="mt-0.5 text-[11px] text-slate-400">
                Saved on this device
              </p>
            </div>

            <span className="rounded-full bg-blue-500/10 px-2.5 py-1 text-xs font-black text-blue-600">
              {conversations.length}
            </span>
          </div>
        </div>
      </aside>

      {/* Main chat */}
      <section className="flex min-w-0 flex-1 flex-col">
        {/* Header */}
        <header className="relative z-20 border-b border-slate-200/80 bg-white/85 px-4 py-3 backdrop-blur-xl dark:border-slate-800 dark:bg-slate-900/85 sm:px-6">
          <div className="mx-auto flex max-w-6xl items-center justify-between gap-4">
            <div className="flex min-w-0 items-center gap-3">
              <button
                type="button"
                onClick={() =>
                  setMobileSidebarOpen(true)
                }
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 text-slate-600 lg:hidden dark:border-slate-700 dark:text-slate-300"
              >
                <Menu className="h-5 w-5" />
              </button>

              {!sidebarOpen && (
                <button
                  type="button"
                  onClick={() =>
                    setSidebarOpen(true)
                  }
                  className="hidden h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 text-slate-600 transition hover:bg-slate-50 lg:flex dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                >
                  <ChevronRight className="h-5 w-5" />
                </button>
              )}

              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-violet-600 shadow-lg shadow-blue-500/20">
                <Bot className="h-5 w-5 text-white" />
              </div>

              <div className="min-w-0">
                <h1 className="truncate text-base font-black text-slate-900 dark:text-white sm:text-lg">
                  {currentConversation?.title ||
                    "AI Assistant"}
                </h1>

                <div className="mt-0.5 flex items-center gap-2 text-xs text-slate-500">
                  <span className="h-2 w-2 rounded-full bg-emerald-500 shadow-[0_0_0_3px_rgba(16,185,129,0.12)]" />
                  Online
                  <span>•</span>
                  <span>
                    {totalMessages} message
                    {totalMessages !== 1 ? "s" : ""}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() =>
                  createNewConversation()
                }
                className="hidden h-10 items-center gap-2 rounded-xl border border-slate-200 px-3 text-sm font-bold text-slate-700 transition hover:bg-slate-50 sm:flex dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                <Plus className="h-4 w-4" />
                New
              </button>

              {currentConversation && (
                <button
                  type="button"
                  onClick={() => {
                    setConversationToDelete(
                      currentConversation
                    );
                    setShowDeleteModal(true);
                  }}
                  className="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-500 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 dark:border-slate-700 dark:hover:border-red-500/20 dark:hover:bg-red-500/10"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>
        </header>

        {/* Conversation */}
        <div className="flex-1 overflow-y-auto">
          <div className="mx-auto flex min-h-full max-w-5xl flex-col px-4 py-6 sm:px-6 lg:px-8">
            {messages.length === 0 ? (
              <div className="flex flex-1 flex-col items-center justify-center py-10 text-center">
                <div className="relative">
                  <div className="absolute inset-0 rounded-[32px] bg-blue-500/20 blur-2xl" />

                  <div className="relative flex h-24 w-24 items-center justify-center rounded-[30px] bg-gradient-to-br from-blue-600 to-violet-600 shadow-2xl shadow-blue-500/25">
                    <Sparkles className="h-11 w-11 text-white" />
                  </div>
                </div>

                <div className="mt-7 inline-flex items-center gap-2 rounded-full border border-blue-500/15 bg-blue-500/5 px-3 py-1.5 text-xs font-bold text-blue-600">
                  <span className="h-2 w-2 rounded-full bg-emerald-500" />
                  Powered by your school data
                </div>

                <h2 className="mt-5 max-w-2xl text-3xl font-black tracking-tight text-slate-900 dark:text-white sm:text-4xl">
                  How can I help you today?
                </h2>

                <p className="mt-3 max-w-xl text-sm leading-6 text-slate-500 sm:text-base">
                  Ask questions about courses, exams, grades,
                  attendance, schedules, or any general topic.
                </p>

                <div className="mt-8 grid w-full max-w-3xl grid-cols-1 gap-3 sm:grid-cols-2">
                  {QUICK_PROMPTS.map((item) => (
                    <button
                      key={item.title}
                      type="button"
                      onClick={() =>
                        sendMessage(item.prompt)
                      }
                      className="group rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-blue-300 hover:shadow-lg dark:border-slate-800 dark:bg-slate-900 dark:hover:border-blue-500/40"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-xl transition group-hover:bg-blue-500/10 dark:bg-slate-800">
                          {item.icon}
                        </div>

                        <div className="min-w-0">
                          <p className="font-bold text-slate-800 dark:text-slate-100">
                            {item.title}
                          </p>

                          <p className="mt-1 truncate text-xs text-slate-500">
                            {item.prompt}
                          </p>
                        </div>

                        <ChevronRight className="ml-auto h-4 w-4 shrink-0 text-slate-300 transition group-hover:translate-x-1 group-hover:text-blue-500" />
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="space-y-7 pb-4">
                {messages.map((message, index) => (
                  <MessageBubble
                    key={message.id || index}
                    message={message}
                  />
                ))}

                {isLoading && (
                  <div className="flex items-start gap-3">
                    <Avatar type="ai" />

                    <div className="rounded-3xl rounded-tl-md border border-slate-200 bg-white px-5 py-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                      <div className="flex items-center gap-3">
                        <div className="flex gap-1.5">
                          {[0, 1, 2].map((dot) => (
                            <span
                              key={dot}
                              className="h-2 w-2 animate-bounce rounded-full bg-blue-500"
                              style={{
                                animationDelay: `${dot * 0.16}s`,
                              }}
                            />
                          ))}
                        </div>

                        <span className="text-xs font-semibold text-slate-500">
                          AI is thinking…
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                <div ref={messagesEndRef} />
              </div>
            )}
          </div>
        </div>

        {/* Composer */}
        <footer className="border-t border-slate-200/80 bg-white/90 px-4 py-4 backdrop-blur-xl dark:border-slate-800 dark:bg-slate-900/90 sm:px-6">
          <div className="mx-auto max-w-5xl">
            {selectedFile && (
              <div className="mb-3 inline-flex items-center gap-3 rounded-xl border border-blue-200 bg-blue-50 px-3 py-2 text-sm dark:border-blue-500/20 dark:bg-blue-500/10">
                <FileText className="h-4 w-4 text-blue-600" />

                <span className="max-w-[240px] truncate font-semibold text-blue-700 dark:text-blue-300">
                  {selectedFile.name}
                </span>

                <button
                  type="button"
                  onClick={() =>
                    setSelectedFile(null)
                  }
                  className="text-blue-500"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}

            <div className="rounded-3xl border border-slate-200 bg-white p-2 shadow-xl shadow-slate-200/50 transition focus-within:border-blue-400 focus-within:ring-4 focus-within:ring-blue-500/10 dark:border-slate-700 dark:bg-slate-950 dark:shadow-black/20">
              <textarea
                ref={textareaRef}
                value={inputMessage}
                onChange={(event) =>
                  setInputMessage(
                    event.target.value.slice(0, 1000)
                  )
                }
                onKeyDown={handleKeyDown}
                placeholder="Ask anything about your school or studies…"
                rows={1}
                disabled={isLoading}
                className="max-h-40 min-h-[54px] w-full resize-none bg-transparent px-4 py-3 text-[15px] leading-6 text-slate-900 outline-none placeholder:text-slate-400 disabled:cursor-not-allowed dark:text-white"
              />

              <div className="flex items-center justify-between gap-3 px-2 pb-1">
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={() =>
                      fileInputRef.current?.click()
                    }
                    disabled={isLoading}
                    className="flex h-10 items-center gap-2 rounded-xl px-3 text-sm font-semibold text-slate-500 transition hover:bg-slate-100 hover:text-slate-900 disabled:opacity-50 dark:hover:bg-slate-800 dark:hover:text-white"
                  >
                    <Paperclip className="h-4 w-4" />
                    <span className="hidden sm:inline">
                      Attach
                    </span>
                  </button>

                  <span className="hidden text-xs text-slate-400 sm:inline">
                    {inputMessage.length}/1000
                  </span>
                </div>

                <button
                  type="button"
                  onClick={() => sendMessage()}
                  disabled={
                    !inputMessage.trim() ||
                    isLoading
                  }
                  className="flex h-11 items-center gap-2 rounded-2xl bg-gradient-to-r from-blue-600 to-violet-600 px-4 text-sm font-bold text-white shadow-lg shadow-blue-500/20 transition hover:-translate-y-0.5 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:translate-y-0"
                >
                  <span className="hidden sm:inline">
                    Send
                  </span>
                  <ArrowUp className="h-4 w-4" />
                </button>
              </div>
            </div>

            <input
              ref={fileInputRef}
              type="file"
              onChange={handleFileSelect}
              className="hidden"
              accept="image/*,application/pdf,text/*"
            />

            <p className="mt-2 text-center text-[11px] text-slate-400">
              AI responses may contain mistakes. Verify important
              academic information.
            </p>
          </div>
        </footer>
      </section>

      {/* Delete modal */}
      {showDeleteModal && conversationToDelete && (
        <div className="fixed inset-0 z-[70] flex items-center justify-center bg-slate-950/65 px-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900">
            <div className="flex items-start gap-4">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-red-500/10">
                <Trash2 className="h-6 w-6 text-red-600" />
              </div>

              <div>
                <h3 className="text-lg font-black text-slate-900 dark:text-white">
                  Delete conversation?
                </h3>

                <p className="mt-1 text-sm leading-6 text-slate-500">
                  This will permanently delete “
                  {conversationToDelete.title}” and all
                  saved messages.
                </p>
              </div>
            </div>

            <div className="mt-6 flex gap-3">
              <button
                type="button"
                onClick={() => {
                  setShowDeleteModal(false);
                  setConversationToDelete(null);
                }}
                className="h-11 flex-1 rounded-xl border border-slate-200 text-sm font-bold text-slate-700 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                Cancel
              </button>

              <button
                type="button"
                onClick={async () => {
                  await deleteConversation(
                    conversationToDelete.id
                  );
                  setShowDeleteModal(false);
                  setConversationToDelete(null);
                }}
                className="h-11 flex-1 rounded-xl bg-red-600 text-sm font-bold text-white transition hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

function MessageBubble({ message }) {
  const isUser = message.sender === "user";

  return (
    <div
      className={`flex items-start gap-3 ${
        isUser ? "justify-end" : "justify-start"
      }`}
    >
      {!isUser && <Avatar type="ai" />}

      <div
        className={`max-w-[84%] sm:max-w-[74%] ${
          isUser ? "items-end" : "items-start"
        }`}
      >
        <div
          className={`rounded-3xl px-5 py-3.5 text-[15px] leading-7 shadow-sm ${
            isUser
              ? "rounded-tr-md bg-gradient-to-br from-blue-600 to-violet-600 text-white shadow-blue-500/10"
              : message.isError
              ? "rounded-tl-md border border-red-200 bg-red-50 text-red-700 dark:border-red-500/20 dark:bg-red-500/10 dark:text-red-300"
              : "rounded-tl-md border border-slate-200 bg-white text-slate-700 dark:border-slate-800 dark:bg-slate-900 dark:text-slate-200"
          }`}
        >
          {message.fileName && (
            <div className="mb-3 flex items-center gap-2 rounded-xl bg-black/10 px-3 py-2 text-xs font-semibold">
              <Upload className="h-4 w-4" />
              {message.fileName}
            </div>
          )}

          <p className="whitespace-pre-wrap break-words">
            {message.text}
          </p>
        </div>

        <div
          className={`mt-1.5 flex items-center gap-1.5 px-2 text-[11px] text-slate-400 ${
            isUser ? "justify-end" : "justify-start"
          }`}
        >
          <Clock3 className="h-3 w-3" />
          {message.timestamp}
        </div>
      </div>

      {isUser && <Avatar type="user" />}
    </div>
  );
}

function Avatar({ type }) {
  const isAI = type === "ai";

  return (
    <div
      className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl shadow-lg ${
        isAI
          ? "bg-gradient-to-br from-blue-600 to-violet-600 shadow-blue-500/15"
          : "bg-slate-900 shadow-slate-900/10 dark:bg-slate-700"
      }`}
    >
      {isAI ? (
        <Bot className="h-5 w-5 text-white" />
      ) : (
        <User className="h-5 w-5 text-white" />
      )}
    </div>
  );
}

function formatConversationDate(date) {
  if (!date) {
    return "Today";
  }

  const value = new Date(date);

  if (Number.isNaN(value.getTime())) {
    return "Recently";
  }

  const today = new Date();

  if (
    value.toDateString() === today.toDateString()
  ) {
    return value.toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  return value.toLocaleDateString([], {
    day: "numeric",
    month: "short",
  });
}
