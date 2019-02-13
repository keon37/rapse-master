test = b"\xba\xd0\xb4\xa2\xc3\xb3\xb8\xae\xc0\xe5"

test2 = test.decode('euc-kr')

print("=======================")
print(test2)

test3 = b"<c3><e6>u<U+00BA><U+03F5><U+00B5>_<c3><e6><c1><U+05BD><c3>"

test4 = test3.decode('utf-8')

print("=======================")
print(test4)