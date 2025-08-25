///| wrap ic0 ffi interface

// 获取FixedArray的头指针，前8 bytes是gc头
extern "wasm" fn getptr(x : FixedArray[Byte]) -> Int =
  #|(func
  #|(param $arr i32)
  #|(result i32)
  #|(i32.add (local.get $arr) (i32.const 8)))

///| 返回当前 Canister 的 Cycle 余额（64 位无符号）。
///
/// 对应 `ic_cdk::api::canister_balance()`。若余额超过 `UInt64` 范围，将截断高位。
pub fn canister_balance_wrap() -> UInt64 {
  canister_cycle_balance().reinterpret_as_uint64()
}

///| 返回当前 Canister 的 Cycle 余额（完整 128 位）。
///
/// 对应 `ic_cdk::api::canister_balance128()`，返回完整的 Cycle 余额。
/// 使用 [`BigInt`](BigInt) 表示可能超过 64 位范围的值。
pub fn canister_balance128_wrap() -> BigInt {
  // 准备16字节缓冲区用于存储结果
  let buf = FixedArray::make(16, b'\x00')
  // 调用系统API，将128位Cycle余额写入缓冲区（小端序）
  canister_cycle_balance128(getptr(buf))
  // 将小端序的16字节转换为 BigInt
  // 需要将缓冲区按大端序构造以正确解析为正整数
  let be_bytes = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    be_bytes[i] = buf[15 - i]
  }
  BigInt::from_octets(Bytes::from_fixedarray(be_bytes))
}

///| 返回当前消息中可用的 Cycle 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_available()`，表示此次调用传入且尚未被接受的 cycles 数量，超过 `UInt64` 范围的值将被截断。
pub fn msg_cycles_available_wrap() -> UInt64 {
  msg_cycles_available().reinterpret_as_uint64()
}

///| 返回当前消息中可用的 Cycle 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_available128()`，返回完整的可用 cycles 数量，使用 [`BigInt`](BigInt) 表示。
pub fn msg_cycles_available128_wrap() -> BigInt {
  let buf = FixedArray::make(16, b'\x00')
  msg_cycles_available128(getptr(buf))
  let be_bytes = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    be_bytes[i] = buf[15 - i]
  }
  BigInt::from_octets(Bytes::from_fixedarray(be_bytes))
}

///| 返回当前调用退款的 Cycle 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_refunded()`，即前一接口调用后未使用而退款的 cycles 数量，超过64位将截断。
pub fn msg_cycles_refunded_wrap() -> UInt64 {
  msg_cycles_refunded().reinterpret_as_uint64()
}

///| 返回当前调用退款的 Cycle 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_refunded128()`，返回完整的退款 cycles 数量。
pub fn msg_cycles_refunded128_wrap() -> BigInt {
  let buf = FixedArray::make(16, b'\x00')
  msg_cycles_refunded128(getptr(buf))
  let be_bytes = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    be_bytes[i] = buf[15 - i]
  }
  BigInt::from_octets(Bytes::from_fixedarray(be_bytes))
}

///| 接受指定数量的循环（cycles），返回实际接受的 cycles 数量（64 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_accept(max_amount: u64)`。
/// 参数为希望接受的 cycles 数量，返回实际接受的数量（可能因为可用 cycles 不足而小于请求值）。
pub fn msg_cycles_accept_wrap(max_amount : UInt64) -> UInt64 {
  msg_cycles_accept(max_amount.reinterpret_as_int64()).reinterpret_as_uint64()
}

///| 接受指定数量的循环（cycles），返回实际接受的 cycles 数量（完整 128 位）。
///
/// 对应 `ic_cdk::api::msg_cycles_accept128(max_amount: u128)`。
/// 参数和返回值使用 [`BigInt`](BigInt) 表示，确保完整的 128 位精度。
pub fn msg_cycles_accept128_wrap(max_amount : BigInt) -> BigInt {
  // 将 BigInt 拆分为高64位和低64位
  // 构造 16 字节大端序表示
  let input_bytes = max_amount.to_octets()
  let high_bytes = FixedArray::make(8, b'\x00')
  let low_bytes = FixedArray::make(8, b'\x00')
  for i = 0; i < 8; i = i + 1 {
    high_bytes[i] = input_bytes[i]
    low_bytes[i] = input_bytes[i + 8]
  }

  // 计算高低64位的数值
  let mut high_val : UInt64 = 0UL
  for i = 0; i < high_bytes.length(); i = i + 1 {
    high_val = (high_val << 8) | high_bytes[i].to_uint64()
  }
  let mut low_val : UInt64 = 0UL
  for i = 0; i < low_bytes.length(); i = i + 1 {
    low_val = (low_val << 8) | low_bytes[i].to_uint64()
  }
  let high_i64 = high_val.reinterpret_as_int64()
  let low_i64 = low_val.reinterpret_as_int64()

  // 准备结果缓冲区
  let result_buf = FixedArray::make(16, b'\x00')
  // 调用系统API接受cycles，将实际接受量写入缓冲区（小端序）
  msg_cycles_accept128(high_i64, low_i64, getptr(result_buf))
  // 转换结果为 BigInt
  let be_bytes = FixedArray::make(16, b'\x00')
  for i = 0; i < 16; i = i + 1 {
    be_bytes[i] = result_buf[15 - i]
  }
  BigInt::from_octets(Bytes::from_fixedarray(be_bytes))
}

///| 获取当前查询调用的认证数据证书。
///
/// 对应 `ic_cdk::api::data_certificate()`，仅在查询调用中有效。
/// 如果存在认证数据证书，则返回其字节内容，否则返回 `None`。
pub fn data_certificate_wrap() -> Bytes? {
  let size = data_certificate_size()
  if size == 0 {
    None
  } else {
    let cert = FixedArray::make(size, b'\x00')
    data_certificate_copy(getptr(cert), 0, size)
    Some(Bytes::from_fixedarray(cert))
  }
}

///| 设置当前 Canister 的认证数据。
///
/// 对应 `ic_cdk::api::set_certified_data(data)`，将指定的数据写入认证哈希。
/// 仅允许最多32字节的数据，多余部分将被截断。
pub fn set_certified_data_wrap(data : Bytes) -> Unit {
  let len = data.length()
  // 如果数据超过32字节，只使用前32字节
  let use_len = if len > 32 { 32 } else { len }
  certified_data_set(getptr(data.to_fixedarray()), use_len)
}

///| 返回当前系统时间（纳秒）。
///
/// 对应 `ic_cdk::api::time()`，返回 IC 运行的标准实时时间，单位为纳秒。
pub fn time_wrap() -> UInt64 {
  time().reinterpret_as_uint64()
}

///| 返回性能计数器的当前值。
///
/// 对应 `ic_cdk::api::performance_counter(counter_type)`，通常用于获取指令执行量等指标。
/// `counter_type` 通常传入0表示获取已用指令数。
pub fn performance_counter_wrap(counter_type : UInt) -> UInt64 {
  performance_counter(counter_type.reinterpret_as_int()).reinterpret_as_uint64()
}

///| 打印调试消息到控制台日志。
///
/// 对应 `ic_cdk::api::print(msg)`。仅用于调试，在生产环境应避免使用。
pub fn print_wrap(msg : String) -> Unit {
  // 将字符串转换为 UTF-8 字节序列
  let utf8_bytes = msg.to_bytes()
  debug_print(getptr(utf8_bytes.to_fixedarray()), utf8_bytes.length())
}

///| 触发调试陷阱，终止执行并返回错误消息。
///
/// 对应 `ic_cdk::api::trap(msg)`，立即停止执行并报告错误消息。
/// 此函数不会正常返回。
pub fn trap_with_msg(msg : String) -> Unit {
  let utf8_bytes = msg.to_bytes()
  trap(getptr(utf8_bytes.to_fixedarray()), utf8_bytes.length())
}

///| 发送回复消息并结束当前调用。
///
/// 对应 `ic_cdk::api::call::reply()`，将回复数据发送给调用方。
/// 注意：调用此函数后应停止后续逻辑以避免重复回复。
pub fn reply_with_data(data : Bytes) -> Unit {
  msg_reply_data_append(getptr(data.to_fixedarray()), data.length())
  msg_reply()
}

///| 拒绝当前调用并返回错误信息给调用方。
///
/// 对应 `ic_cdk::api::call::reject(msg)`，使用拒绝代码 5 表示应用自定义错误。
pub fn reject_with_msg(msg : String) -> Unit {
  let utf8_bytes = msg.to_bytes()
  // 拒绝代码 5 代表 Canister 主动拒绝
  msg_reject(getptr(utf8_bytes.to_fixedarray()), utf8_bytes.length())
}

///| 返回稳定内存大小（页数，每页64KB）。
///
/// 对应 `ic_cdk::api::stable::stable_size()`。返回当前稳定内存的页数。
pub fn stable_size_wrap() -> UInt {
  stable_size().reinterpret_as_uint()
}

///| 增加稳定内存页数，返回扩展前的页数，失败则返回 `None`。
///
/// 对应 `ic_cdk::api::stable::stable_grow(pages)`。
/// 如果请求扩展成功，返回扩展前的页数；若内存不足扩展失败，返回 `None`。
pub fn stable_grow_wrap(new_pages : UInt) -> UInt? {
  let result = stable_grow(new_pages.reinterpret_as_int())
  if result < 0 {
    None
  } else {
    Some(result.reinterpret_as_uint())
  }
}

///| 从稳定内存中读取数据。
///
/// 对应 `ic_cdk::api::stable::stable_read(offset, length)`。
/// 从稳定内存指定偏移处读取 `length` 字节并返回。
pub fn stable_read_wrap(offset : UInt, length : UInt) -> Bytes {
  let buf = FixedArray::make(length.reinterpret_as_int(), b'\x00')
  stable_read(
    getptr(buf),
    offset.reinterpret_as_int(),
    length.reinterpret_as_int(),
  )
  Bytes::from_fixedarray(buf)
}

///| 向稳定内存写入数据。
///
/// 对应 `ic_cdk::api::stable::stable_write(offset, data)`。
/// 将字节序列写入稳定内存指定偏移处。
pub fn stable_write_wrap(offset : UInt, data : Bytes) -> Unit {
  stable_write(
    offset.reinterpret_as_int(),
    getptr(data.to_fixedarray()),
    data.length(),
  )
}

///| 返回稳定内存大小（页数，64位）。
///
/// 对应 `ic_cdk::api::stable::stable64_size()`，以 64 位整数返回当前稳定内存页数。
pub fn stable64_size_wrap() -> UInt64 {
  stable64_size().reinterpret_as_uint64()
}

///| 增加稳定内存页数（64位），返回扩展前的页数或 `None` 表示失败。
///
/// 对应 `ic_cdk::api::stable::stable64_grow(pages)`。
/// 参数和返回值使用 64 位计数。
pub fn stable64_grow_wrap(new_pages : UInt64) -> UInt64? {
  let result = stable64_grow(new_pages.reinterpret_as_int64())
  if result < 0L {
    None
  } else {
    Some(result.reinterpret_as_uint64())
  }
}

///| 从稳定内存（支持64位偏移）读取数据。
///
/// 对应 `ic_cdk::api::stable::stable64_read(offset, length)`。
/// 支持超过4GB偏移的读取。
pub fn stable64_read_wrap(offset : UInt64, length : UInt64) -> Bytes {
  let buf = FixedArray::make(length.to_int(), b'\x00')
  stable64_read(
    getptr(buf).to_int64(),
    offset.reinterpret_as_int64(),
    length.reinterpret_as_int64(),
  )
  Bytes::from_fixedarray(buf)
}

///| 向稳定内存写入数据（支持64位偏移）。
///
/// 对应 `ic_cdk::api::stable::stable64_write(offset, data)`。
/// 支持超过4GB偏移的写入。
pub fn stable64_write_wrap(offset : UInt64, data : Bytes) -> Unit {
  stable64_write(
    offset.reinterpret_as_int64(),
    getptr(data.to_fixedarray()).to_int64(),
    data.length().to_int64(),
  )
}
