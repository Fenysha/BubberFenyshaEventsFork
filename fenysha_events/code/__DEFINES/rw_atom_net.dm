#define OBJECT_NET_POWER  0
#define OBJECT_NET_FLUID  1
#define OBJECT_NET_ATMOS  2
#define OBJECT_NET_DATA   3


#define POWER_SLOT_SUPPLY   0
#define POWER_SLOT_DEMAND   1
#define POWER_SLOT_CAPACITY 2
#define POWER_SLOT_CHARGE   3
#define POWER_SLOT_MAX_IN   4
#define POWER_SLOT_MAX_OUT  5


#define SMOOTH_GROUP_CABLE_ELECTRIC S_TURF(220) //! /obj/structure/object_net_cable


#define ONET_KIND_CONNECTOR          0
#define ONET_KIND_PRODUCER           1
#define ONET_KIND_STORE              2
#define ONET_KIND_SWITCH             3
#define ONET_MASK_ATTACH             ((1<<0)|(1<<1)|(1<<2))


#define ONET_RECONNECT_DELAY (4 SECONDS)
#define ONET_DEFAULT_RANGE 1
