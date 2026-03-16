s = "bbbaaaba"

t = "aaabbbba"

def isIsomorphic(s, t):
    
    set_a = {}
    set_b = {}
    list_s = list(s)
    list_t = list(t)
    for key in set(s):
        set_a[key] = list_s.count(key)
    set_a_keys = list(set_a.keys())
    for key in set(t):
        set_b[key] = list_t.count(key)
    set_b_keys = list(set_b.keys())

    for i in range(len(set_a_keys)):
        if set_a[set_a_keys[i]] != set_b[set_b_keys[i]]:
            print("No")
    print("True")

isIsomorphic(s, t)