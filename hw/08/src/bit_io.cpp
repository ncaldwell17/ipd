#include "bit_io.h"

#include <ios>

namespace ipd {

using std::ios;

bistream &bistream::read(bool &bit) {
    if (nbits == 0) {
        if (!next_byte(bitbuf)) return *this;
        nbits = 8;
    }

    --nbits;
    bit = (bitbuf >> nbits & 1) == 1;

    return *this;
}

bistream::operator bool() const {
    return good();
}

bistream_adaptor::bistream_adaptor(std::istream& is) : stream_(is)
{ }

bool bistream_adaptor::next_byte(char &bitbuf) {
    return (bool) stream_.read(&bitbuf, 1);
}

bool bistream_adaptor::good() const {
    return nbits > 0 || stream_.good();
}

bool bistream_adaptor::eof() const {
    return nbits == 0 && stream_.eof();
}

bistringstream::bistringstream(std::vector<unsigned char> v)
        : bytes(v), bytes_index(0) {}

static std::vector<unsigned char>
bits_to_chars(std::initializer_list<bool> bits)
{
    bostringstream oss;
    for (bool bit : bits) oss << bit;
    return oss.data();
}

bistringstream::bistringstream(std::initializer_list<bool> bits)
        : bistringstream(bits_to_chars(bits))
{ }

bool bistringstream::next_byte(char &bitbuf) {
    if (bytes_index < bytes.size()) {
        bitbuf = bytes[bytes_index];
        bytes_index++;
        return true;
    }
    bitbuf = 0;
    return false;
}

bool bistringstream::good() const {
    return nbits > 0 || bytes_index < bytes.size();
}

size_t bostringstream::bits_written() const
{
    return bits_written_;
}

bool bistringstream::eof() const {
    return nbits == 0 && bytes_index == bytes.size();
}

bifstream::bifstream(const char *filespec)
        : stream(filespec, ios::binary)
        , bistream_adaptor(stream)
{}

bostream_adaptor::bostream_adaptor(std::ostream& os)
        : stream_(os)
{}

bostream_adaptor &bostream_adaptor::write(bool bit) {
    bitbuf |= ((char) bit) << (7 - nbits);

    if (++nbits == 8) write_out();

    return *this;
}

bool bostream_adaptor::good() const {
    return stream_.good();
}

void bostream_adaptor::write_out() {
    if (stream_.write(&bitbuf, 1)) {
        bitbuf = 0;
        nbits = 0;
    }
}

bostream_adaptor::~bostream_adaptor() {
    if (nbits) {
        write_out();
    }
}

bostream::operator bool() const {
    return good();
}

bofstream::bofstream(const char *filespec)
        : stream(filespec, ios::binary | ios::trunc)
        , bostream_adaptor(stream)
{}

bool bostringstream::good() const {
    return true;
}

bostringstream &bostringstream::write(bool bit) {
    auto index = bits_written_ / 8;
    auto nbits = bits_written_ % 8;
    if (index >= data_.size()) data_.push_back(0);
    data_[index] |= ((unsigned char) bit) << (7 - nbits);
    bits_written_++;
    return *this;
}

const std::vector<unsigned char>& bostringstream::data() const {
    return data_;
}

}

