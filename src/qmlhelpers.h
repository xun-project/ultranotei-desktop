#pragma once

#include <QObject>
#include <QtQml>

#define QML_WRITABLE_PROPERTY(type, name, setter, defaultValue)             \
protected:                                                                  \
    Q_PROPERTY(type name MEMBER m_##name WRITE setter NOTIFY name##Changed) \
public:                                                                     \
    void setter(const type& value)                                          \
    {                                                                       \
        if (value != m_##name) {                                            \
            m_##name = value;                                               \
            emit name##Changed();                                           \
        }                                                                   \
    }                                                                       \
    const type& name() const { return m_##name; }                           \
Q_SIGNALS:                                                                  \
    void name##Changed();                                                   \
                                                                            \
private:                                                                    \
    type m_##name = defaultValue;

#define QML_WRITABLE_PROPERTY_FLOAT(type, name, setter, defaultValue)       \
protected:                                                                  \
    Q_PROPERTY(type name MEMBER m_##name WRITE setter NOTIFY name##Changed) \
public:                                                                     \
    void setter(type value)                                                 \
    {                                                                       \
        if (!qFuzzyCompare(value, m_##name)) {                              \
            m_##name = value;                                               \
            emit name##Changed();                                           \
        }                                                                   \
    }                                                                       \
    const type& name() const { return m_##name; }                           \
Q_SIGNALS:                                                                  \
    void name##Changed();                                                   \
                                                                            \
private:                                                                    \
    type m_##name = defaultValue;

#define QML_READABLE_PROPERTY(type, name, setter, defaultValue) \
protected:                                                      \
    Q_PROPERTY(type name MEMBER m_##name NOTIFY name##Changed)  \
public:                                                         \
    void setter(const type& value)                              \
    {                                                           \
        if (value != m_##name) {                                \
            m_##name = value;                                   \
            emit name##Changed();                               \
        }                                                       \
    }                                                           \
Q_SIGNALS:                                                      \
    void name##Changed();                                       \
                                                                \
private:                                                        \
    type m_##name = defaultValue;

#define QML_READABLE_PROPERTY_FLOAT(type, name, setter, defaultValue) \
protected:                                                            \
    Q_PROPERTY(type name MEMBER m_##name NOTIFY name##Changed)        \
public:                                                               \
    void setter(const type& value)                                    \
    {                                                                 \
        if (!qFuzzyCompare(value, m_##name)) {                        \
            m_##name = value;                                         \
            emit name##Changed();                                     \
        }                                                             \
    }                                                                 \
Q_SIGNALS:                                                            \
    void name##Changed();                                             \
                                                                      \
private:                                                              \
    type m_##name = defaultValue;

#define QML_CONSTANT_PROPERTY(type, name, defaultValue) \
protected:                                              \
    Q_PROPERTY(type name MEMBER m_##name CONSTANT)      \
private:                                                \
    const type m_##name = defaultValue;

#define QML_CONSTANT_PROPERTY_PTR(type, name)       \
protected:                                          \
    Q_PROPERTY(type* name MEMBER m_##name CONSTANT) \
public:                                             \
    type* name() { return m_##name; }               \
                                                    \
private:                                            \
    type* m_##name = new type(this);

#define QML_REGISTER_ENUM(enumeration_name, ...)                                                                       \
    class enumeration_name##Class {                                                                                    \
        Q_GADGET                                                                                                       \
    public:                                                                                                            \
        enum Value {                                                                                                   \
            __VA_ARGS__                                                                                                \
        };                                                                                                             \
        Q_ENUM(Value)                                                                                                  \
        static QString toString(const int value)                                                                       \
        {                                                                                                              \
            return QString::fromLatin1(staticMetaObject.enumerator(0).valueToKey(value));                              \
        }                                                                                                              \
        static void registerQmlEnum(const char* uri, const int majorVersion, const int minorVersion, const char* name) \
        {                                                                                                              \
            qRegisterMetaType<enumeration_name##Class::Value>(#enumeration_name);                                      \
            qmlRegisterUncreatableType<enumeration_name##Class>(uri, majorVersion, minorVersion, name,                 \
                #enumeration_name " can not creatable as it is an enum type");                                         \
        }                                                                                                              \
                                                                                                                       \
    private:                                                                                                           \
        explicit enumeration_name##Class() = default;                                                                  \
    };                                                                                                                 \
    typedef enumeration_name##Class::Value enumeration_name;

// NOTE : to avoid "no suitable class found" MOC note
class QmlProperty : public QObject {
    Q_OBJECT
};
