export type AppRole = "customer" | "staff" | "rider" | "admin";

export type OrderStatus = "placed" | "confirmed" | "preparing" | "ready" | "en_route" | "delivered" | "cancelled";
export type PaymentMethod = "cash" | "momo" | "paystack";
export type PaymentStatus = "unpaid" | "pending" | "paid" | "failed" | "refunded";

export type PromoType = "percent" | "fixed";

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          name: string | null;
          phone: string | null;
          default_delivery_note: string | null;
          role: AppRole;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["profiles"]["Row"]> & Pick<Database["public"]["Tables"]["profiles"]["Row"], "id">;
        Update: Partial<Database["public"]["Tables"]["profiles"]["Row"]>;
        Relationships: [];
      };

      categories: {
        Row: {
          id: string;
          name: string;
          is_active: boolean;
          sort_order: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["categories"]["Row"]> & Pick<Database["public"]["Tables"]["categories"]["Row"], "name">;
        Update: Partial<Database["public"]["Tables"]["categories"]["Row"]>;
        Relationships: [];
      };

      menu_items: {
        Row: {
          id: string;
          category_id: string | null;
          name: string;
          description: string | null;
          base_price: number;
          image_url: string | null;
          spice_level: number;
          is_active: boolean;
          is_sold_out: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["menu_items"]["Row"]> &
          Pick<Database["public"]["Tables"]["menu_items"]["Row"], "name" | "base_price">;
        Update: Partial<Database["public"]["Tables"]["menu_items"]["Row"]>;
        Relationships: [];
      };

      promos: {
        Row: {
          id: string;
          code: string;
          type: PromoType;
          value: number;
          min_subtotal: number;
          expires_at: string | null;
          is_active: boolean;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["promos"]["Row"]> & Pick<Database["public"]["Tables"]["promos"]["Row"], "code" | "type" | "value">;
        Update: Partial<Database["public"]["Tables"]["promos"]["Row"]>;
        Relationships: [];
      };

      orders: {
        Row: {
          id: string;
          user_id: string;
          status: OrderStatus;
          subtotal: number;
          delivery_fee: number;
          discount: number;
          tip: number;
          total: number;
          payment_method: PaymentMethod;
          payment_status: PaymentStatus;
          payment_reference: string | null;
          address_snapshot: Record<string, unknown>;
          scheduled_for: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["orders"]["Row"]> &
          Pick<Database["public"]["Tables"]["orders"]["Row"], "user_id" | "subtotal" | "total">;
        Update: Partial<Database["public"]["Tables"]["orders"]["Row"]>;
        Relationships: [];
      };

      order_items: {
        Row: {
          id: string;
          order_id: string;
          item_id: string | null;
          name_snapshot: string;
          variant_snapshot: string | null;
          addons_snapshot: unknown[];
          qty: number;
          price: number;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["order_items"]["Row"]> &
          Pick<Database["public"]["Tables"]["order_items"]["Row"], "order_id" | "name_snapshot" | "qty" | "price">;
        Update: Partial<Database["public"]["Tables"]["order_items"]["Row"]>;
        Relationships: [];
      };

      order_status_events: {
        Row: {
          id: string;
          order_id: string;
          status: OrderStatus;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["order_status_events"]["Row"]> &
          Pick<Database["public"]["Tables"]["order_status_events"]["Row"], "order_id" | "status">;
        Update: Partial<Database["public"]["Tables"]["order_status_events"]["Row"]>;
        Relationships: [];
      };

      chats: {
        Row: {
          id: string;
          order_id: string;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["chats"]["Row"]> & Pick<Database["public"]["Tables"]["chats"]["Row"], "order_id">;
        Update: Partial<Database["public"]["Tables"]["chats"]["Row"]>;
        Relationships: [];
      };

      chat_messages: {
        Row: {
          id: string;
          chat_id: string;
          sender_id: string | null;
          message: string;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["chat_messages"]["Row"]> &
          Pick<Database["public"]["Tables"]["chat_messages"]["Row"], "chat_id" | "message">;
        Update: Partial<Database["public"]["Tables"]["chat_messages"]["Row"]>;
        Relationships: [];
      };

      notifications: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          body: string;
          is_read: boolean;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["notifications"]["Row"]> &
          Pick<Database["public"]["Tables"]["notifications"]["Row"], "user_id" | "title" | "body">;
        Update: Partial<Database["public"]["Tables"]["notifications"]["Row"]>;
        Relationships: [];
      };

      delivery_settings: {
        Row: {
          id: string;
          base_fee: number;
          free_radius_km: number;
          per_km_fee_after_free_radius: number;
          minimum_order_amount: number;
          max_delivery_distance_km: number;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["delivery_settings"]["Row"]>;
        Update: Partial<Database["public"]["Tables"]["delivery_settings"]["Row"]>;
        Relationships: [];
      };

      staff_notifications: {
        Row: {
          id: string;
          recipient_id: string;
          type: "new_order" | "customer_message" | "system";
          title: string;
          body: string | null;
          entity_type: string | null;
          entity_id: string | null;
          is_read: boolean;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["staff_notifications"]["Row"]> &
          Pick<Database["public"]["Tables"]["staff_notifications"]["Row"], "recipient_id" | "type" | "title">;
        Update: Partial<Database["public"]["Tables"]["staff_notifications"]["Row"]>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
