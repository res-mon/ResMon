package scalar

import (
	"fmt"
	"io"
	"strconv"
	"time"
)

type Timestamp int64

func TimestampFromTime(t time.Time) Timestamp {
	return Timestamp(t.UnixMilli())
}

func (t *Timestamp) UnmarshalGQL(v interface{}) error {
	value, ok := v.(int64)
	if !ok {
		return fmt.Errorf("Timestamp must be a int64")
	}

	*t = Timestamp(value)
	return nil
}

func (t Timestamp) MarshalGQL(w io.Writer) {
	w.Write([]byte(strconv.FormatInt(int64(t), 10)))
}
