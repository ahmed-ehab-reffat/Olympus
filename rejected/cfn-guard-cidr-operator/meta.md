# Add IP and CIDR comparison operators to the Guard rules language

CloudFormation rules routinely need to reason about IP addresses and CIDR ranges, but the Guard language can only compare them as opaque strings, so a rule cannot tell that `10.1.2.3` falls inside `10.0.0.0/8`. Add five comparison operators that understand IPv4 and IPv6 addressing: `in_cidr`, `cidr_overlaps`, `covered_by`, `is_cidr`, and `is_ip`. Each is written like the existing keyword operators.

`in_cidr` is a binary operator whose left side is an address or a CIDR range and whose right side is a CIDR range. It holds when the entire left side lies within the range denoted by the right side. A bare address is treated as a single host. A range on the left is contained only when every address it covers is also covered by the right side. The right side must carry a prefix length. The network is determined solely by the prefix length, so any host bits set in either operand are ignored when deciding containment. An IPv4 value is never contained in an IPv6 range or the reverse.

`cidr_overlaps` is a binary operator that holds when the two ranges share at least one address, treating a bare address as a single host.

`covered_by` is a binary operator whose left side is an address or a CIDR range and whose right side is a list of CIDR ranges. It holds when every address in the left range lies within the union of the ranges on the right, which can be true even when no single range on the right contains the whole left side. Ranges on the right that belong to a different address family than the left side do not contribute to the coverage.

`is_cidr` holds when a value is a string in CIDR notation, meaning an IPv4 or IPv6 address followed by a prefix length. `is_ip` holds when a value is a string that is a valid IPv4 or IPv6 address without a prefix.

For the binary operators, an operand that is not a string, or a string that is not a valid address or CIDR range, makes the values not comparable rather than silently passing; for `covered_by` this applies to the left side and to every range on the right. Prefix lengths range from zero, which selects every address, up to the full width of the address family.
